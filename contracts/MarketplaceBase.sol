// SPDX-License-Identifier: Unlisened
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import "./interfaces/IGovernance.sol";
import "./interfaces/IMarketplace.sol";

import "./libraries/TokenIdGenerator.sol";

abstract contract MarketplaceBase is
    IMarketplace,
    EIP712Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using TokenIdGenerator for uint256;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using TokenIdGenerator for TokenIdGenerator.Token;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    address public immutable factory;

    uint256 public immutable serviceFee;
    uint256 public immutable creatorFeeUB; // creator fee upper bound

    bytes32 public constant VERSION = "Marketplacev1";

    address public admin;

    bool public isFrozenBase;

    CountersUpgradeable.Counter public nonce;

    bytes32 private constant ITEM_TYPE_HASH =
        keccak256(
            "Item(uint256 amount, uint256 tokenId, uint256 unitPrice, string tokenURI)"
        );
    bytes32 private constant PAYMENT_TYPE_HASH =
        keccak256(
            "Payment(address paymentToken, uint256 subTotal, uint256 creatorPayout, uint256 servicePayout, uint256 total)"
        );
    bytes32 private constant RECEIPT_TYPE_HASH =
        keccak256(
            "Receipt(address buyer, address seller, address creator, address creatorPayoutAddr, Item item, Payment payment, uint256 deadline uint256 nonce"
        );

    string public name;
    string public symbol;

    mapping(uint256 => bool) public frozenTokens;

    modifier onlyManager() {
        require(
            _msgSender() == IGovernance(admin).manager(),
            "Base: ONLY_MANAGER_ALLOWED"
        );
        _;
    }

    modifier onlyFactory() {
        require(_msgSender() == factory, "Base: ONLY_FACTORY_ALLOWED");
        _;
    }

    modifier only32BytesString(string memory str_) {
        require(bytes(str_).length <= 32, "Base: STRING_TOO_LONG");
        _;
    }

    modifier whenNotFrozen(uint256 tokenId_) {
        require(!frozenTokens[tokenId_], "Base: TOKEN_IS_FROZEN");
        _;
    }

    modifier whenNotFrozenBase() {
        require(!isFrozenBase, "Base: BASE_URI_FROZEN");
        _;
    }

    modifier whenNotExpired(uint256 deadline_) {
        require(block.timestamp < deadline_, "Base: SIGNATURE_EXPIRED");
        _;
    }

    constructor(
        uint256 serviceFee_,
        uint256 creatorFeeUB_,
        address admin_,
        address factory_,
        string memory name_,
        string memory symbol_
    ) only32BytesString(name_) only32BytesString(symbol_) {
        admin = admin_;
        factory = factory_;

        serviceFee = serviceFee_ % (2**16 - 1);
        creatorFeeUB = creatorFeeUB_ % (2**16 - 1);

        name = name_;
        symbol = symbol_;
    }

    receive() external payable {
        emit Received(_msgSender(), msg.value, "Received Token");
    }

    fallback() external payable {}

    function kill() external onlyFactory {
        selfdestruct(payable(IGovernance(admin).treasury()));
    }

    function multiDelegatecall(bytes[] calldata data)
        external
        payable
        override
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);
        for (uint256 i; i < data.length; ) {
            (bool ok, bytes memory result) = address(this).delegatecall(
                data[i]
            );
            require(ok, "Base: DELEGATECALL_FAILED");
            results[i] = result;
            unchecked {
                ++i;
            }
        }
    }

    function redeem(
        address seller_,
        address paymentToken_,
        address creatorPayoutAddr_,
        uint256 amount_,
        uint256 tokenId_,
        uint256 deadline_,
        uint256 unitPrice_,
        string calldata tokenURI_,
        bytes calldata signature_
    ) external payable override whenNotPaused whenNotExpired(deadline_) {
        _supplyCheck(tokenId_, amount_);
        address _admin = admin;
        require(
            _isPaymentSupported(_admin, paymentToken_),
            "Base: PAYMENT_NOT_SUPPORTED"
        );

        address buyer = _msgSender();
        address creator = tokenId_.getTokenCreator();

        // prevent stack too deep
        {
            uint256 creatorFee = tokenId_.getCreatorFee();
            (
                uint256 total,
                uint256 subTotal,
                uint256 creatorPayout,
                uint256 servicePayout
            ) = _getPayment(amount_, creatorFee, unitPrice_);

            require(msg.value >= total, "BASE: INSUFFICIENT_PAYMENT");

            Receipt memory receipt = Receipt(
                buyer,
                seller_,
                creator,
                creatorPayoutAddr_,
                Item(amount_, tokenId_, unitPrice_, tokenURI_),
                Payment(
                    paymentToken_,
                    subTotal,
                    creatorPayout,
                    servicePayout,
                    total
                ),
                deadline_,
                nonce.current()
            );

            bytes32 hashedReceipt = _hashReceipt(buyer, receipt);
            _verifySignature(
                IGovernance(_admin).verifier(),
                hashedReceipt,
                signature_
            );
            nonce.increment();

            _transact(paymentToken_, buyer, seller_, subTotal);
            _transact(paymentToken_, buyer, creatorPayoutAddr_, creatorPayout);
            _transact(
                paymentToken_,
                buyer,
                IGovernance(_admin).treasury(),
                servicePayout
            );
        }

        bool minted = _isMintedBefore(seller_, creator, tokenId_, amount_);
        if (!minted) {
            _lazyMint(seller_, tokenId_, amount_, tokenURI_);
        }

        _transferToken(seller_, buyer, amount_, tokenId_);
    }

    function setName(string calldata name_)
        external
        override
        onlyOwner
        only32BytesString(name_)
    {
        name = name_;
    }

    function setSymbol(string calldata symbol_)
        external
        override
        onlyOwner
        only32BytesString(symbol_)
    {
        symbol = symbol_;
    }

    function setAdmin(address admin_) external override onlyManager {
        admin = admin_;
    }

    function freezeBaseURI() external override onlyOwner whenNotFrozenBase {
        isFrozenBase = true;
    }

    function createTokenId(
        uint256 type_,
        uint256 creatorFee_,
        uint256 index_,
        uint256 supply_,
        address creator_
    ) external pure override returns (uint256) {
        return _createTokenId(type_, creatorFee_, index_, supply_, creator_);
    }

    function _transferToken(
        address from_,
        address to_,
        uint256 amount_,
        uint256 tokenId_
    ) internal virtual;

    function _initialize(
        address owner_,
        string memory name_,
        string memory symbol_
    ) internal only32BytesString(name_) only32BytesString(symbol_) {
        require(!owner_.isContract(), "Base: ONLY_EOA_OWNER_ALLOWED");
        __Pausable_init();
        __ReentrancyGuard_init();
        _transferOwnership(owner_);

        name = name_;
        symbol = symbol_;

        __EIP712_init(name_, string(abi.encodePacked(VERSION)));
    }

    function _transact(
        address paymentToken_,
        address from_,
        address to_,
        uint256 amount_
    ) internal nonReentrant {
        if (paymentToken_ == address(0)) {
            (bool ok, ) = payable(to_).call{value: amount_}("");
            require(ok, "Base: PAYMENT_FAILED");
        } else {
            IERC20Upgradeable(paymentToken_).safeTransferFrom(
                from_,
                to_,
                amount_
            );
        }
    }

    function _lazyMint(
        address to_,
        uint256 tokenId_,
        uint256 amount_,
        string calldata tokenURI_
    ) internal virtual;

    function _supplyCheck(uint256 tokenId_, uint256 amount_)
        internal
        view
        virtual;

    function _isMintedBefore(
        address seller_,
        address creator_,
        uint256 tokenId_,
        uint256 amount_
    ) internal view virtual returns (bool);

    function _isPaymentSupported(address admin_, address paymentToken_)
        internal
        view
        returns (bool)
    {
        return IGovernance(admin_).acceptPayment(paymentToken_);
    }

    function _hashReceipt(address buyer, Receipt memory receipt_)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encodePacked(
                        RECEIPT_TYPE_HASH,
                        buyer,
                        receipt_.seller,
                        receipt_.creator,
                        receipt_.creatorPayoutAddr,
                        __hashItem(
                            receipt_.item.amount,
                            receipt_.item.tokenId,
                            receipt_.item.unitPrice,
                            receipt_.item.tokenURI
                        ),
                        __hashPayment(
                            receipt_.payment.paymentToken,
                            receipt_.payment.subTotal,
                            receipt_.payment.creatorPayout,
                            receipt_.payment.creatorPayout,
                            receipt_.payment.total
                        ),
                        receipt_.deadline,
                        receipt_.nonce
                    )
                )
            );
    }

    function _verifySignature(
        address verifier,
        bytes32 data_,
        bytes calldata signature_
    ) internal pure {
        address signer = ECDSAUpgradeable.recover(data_, signature_);
        require(signer == verifier, "Base: INVALID_SIGNER_OR_PARAMS");
    }

    function _getPayment(
        uint256 amount_,
        uint256 creatorFee_,
        uint256 unitPrice_
    )
        internal
        view
        returns (
            uint256 total,
            uint256 subTotal,
            uint256 creatorPayout,
            uint256 servicePayout
        )
    {
        subTotal = amount_ * unitPrice_;
        servicePayout = (subTotal * serviceFee) / 1e4;
        creatorPayout = (subTotal * creatorFee_) / 1e4;
        total = subTotal + servicePayout + creatorPayout;
    }

    function _createTokenId(
        uint256 type_,
        uint256 creatorFee_,
        uint256 index_,
        uint256 supply_,
        address creator_
    ) internal pure returns (uint256) {
        TokenIdGenerator.Token memory token = TokenIdGenerator.Token(
            creatorFee_,
            type_,
            supply_,
            index_,
            creator_
        );
        return token.createTokenId();
    }

    function __hashItem(
        uint256 amount_,
        uint256 tokenId_,
        uint256 unitPrice_,
        string memory tokenURI_
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ITEM_TYPE_HASH,
                    amount_,
                    tokenId_,
                    unitPrice_,
                    keccak256(bytes(tokenURI_))
                )
            );
    }

    function __hashPayment(
        address paymentToken_,
        uint256 subTotal_,
        uint256 creatorPayout_,
        uint256 servicePayout_,
        uint256 total_
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PAYMENT_TYPE_HASH,
                    paymentToken_,
                    subTotal_,
                    creatorPayout_,
                    servicePayout_,
                    total_
                )
            );
    }
}
