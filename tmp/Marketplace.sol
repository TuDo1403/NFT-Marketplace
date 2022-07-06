// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

import "./interfaces/IGovernance.sol";
import "./libraries/TokenIdGenerator.sol";
import "./interfaces/ICollectible1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

/// @custom:security-contact tudm@inspirelab.io
abstract contract MarketplaceBase is
    EIP712,
    Pausable,
    AccessControl,
    Initializable,
    ERC1155Supply,
    ReentrancyGuard,
    ERC1155Burnable,
    ICollectible1155,
    ERC1155URIStorage
{
    using Address for address;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    using TokenIdGenerator for uint256;
    using TokenIdGenerator for TokenIdGenerator.Token;

    Counters.Counter public nonce;

    address public admin;
    address public factory;

    uint16 public constant SERVICE_FEE = 2500; // fee / 1e4
    uint16 public constant CREATOR_FE_UB = 1000; // fee / 1e4

    bytes32 public constant TYPE = keccak256("1155");
    bytes32 public constant VERSION = keccak256("Marketplacev1");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");

    bytes32 public name;
    bytes32 public symbol;

    mapping(uint256 => Creator) public creators;
    mapping(uint256 => uint256) public tokensPrice;

    modifier onlyFactory() {
        require(
            factory == _msgSender(),
            "Marketplace#onlyFactory: ONLY_FACTORY_ALLOWED"
        );
        _;
    }

    modifier onlyCreator(uint256 tokenId) {
        require(
            tokenId.tokenCreator() == _msgSender(),
            "Marketplace#onlyCreator: ONLY_CREATOR_ALLOWED"
        );
        _;
    }

    modifier onlyOwner(uint256 tokenId) {
        require(
            balanceOf(_msgSender(), tokenId) > 0,
            "Marketplace#onlyOwner: ONLY_OWNER_ALLOWED"
        );
        _;
    }

    modifier onlyEOA() {
        require(
            !_msgSender().isContract(),
            "Marketplace#onlyUser: ONLY_EOA_ALLOWED"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address admin_,
        address creator_,
        string memory uri_,
        string memory name_,
        string memory symbol_
    )
        // override(Pausable, ReentrancyGuard)
        ERC1155(uri_)
        EIP712(name_, "Marketplacev1")
    {
        _initialize(admin_, creator_, name_, symbol_);
        _disableInitializers();
    }

    receive() external payable {}

    fallback() external payable {}

    function kill() external onlyFactory {
        selfdestruct(payable(IGovernance(admin).treasury()));
    }

    function initialize(
        address admin_,
        address creator_,
        string calldata uri_,
        string calldata name_,
        string calldata symbol_
    ) external initializer {
        _setURI(uri_);

        _initialize(admin_, creator_, name_, symbol_);
    }

    function _initialize(
        address admin_,
        address creator_,
        string memory name_,
        string memory symbol_
    ) internal {
        admin = admin_;
        factory = _msgSender();

        name = keccak256(bytes(name_));
        symbol = keccak256(bytes(symbol_));

        _grantRole(MINTER_ROLE, creator_);
        _grantRole(PAUSER_ROLE, creator_);
        _grantRole(URI_SETTER_ROLE, creator_);
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    function listItem(
        uint256 tokenId,
        uint256 unitPrice,
        uint256 maxSupply,
        string calldata tokenURI
    ) external {
        if (bytes(tokenURI).length != 0) {
            _setURI(tokenId, tokenURI);
        }
    }

    function _generateTokenId(uint256 creatorFee, uint256 maxSupply)
        internal
        pure
        returns (uint256)
    {
        require(
            creatorFee <= CREATOR_FE_UB,
            "Marketplace#generateToken: INVALID_CREATOR_FEE"
        );
    }

    function buyBatch(uint256[] amounts, address seller, uint256[] tokenIds, )

    function buy(
        uint256 amount,
        address seller,
        uint256 tokenId,
        uint256 deadline,
        uint256 unitPrice,
        uint16 creatorFee,
        address paymentToken,
        bytes calldata signature_
    ) external payable onlyEOA nonReentrant {
        require(
            block.timestamp < deadline,
            "Marketplace#buyToken: SIGNATURE_EXPIRED"
        );
        require(
            IGovernance(admin).acceptPayment(paymentToken),
            "Marketplace#buyToken: UNSUPPORTED_PAYMENT_TOKEN"
        );

        uint256 subTotal = unitPrice * amount;
        uint256 servicePayout = (subTotal * SERVICE_FEE) / 1e4;
        uint256 creatorPayout = (subTotal * creatorFee) / 1e4;
        uint256 total = subTotal + servicePayout + creatorPayout;

        require(
            msg.value >= total,
            "Marketplace#buyToken: INSUFFICIENT_PAYMENT"
        );

        bool mint = false;
        address buyer = _msgSender();
        address creator = tokenId.tokenCreator();

        if (seller != creator) {
            // token must be minted before or seller must have token
            require(
                exists(tokenId) || balanceOf(seller, tokenId) != 0,
                "Marketplace#buyToken: INVALID_SELLER"
            );
            // seller must have enough tokens
            require(
                balanceOf(seller, tokenId) >= amount,
                "Marketplace#buyToken: INVALID_PURCHASE_AMOUNT"
            );
        } else {
            uint256 tokenMaxSupply = tokenId.tokenMaxSupply();
            require(
                amount <= tokenMaxSupply,
                "Marketplace#buyToken: PURCHASE_AMOUNT_>_MAX_SUPPLY"
            );
            mint = true;
        }

        address creatorPayoutAddr = creators[tokenId].payoutAddr;

        bytes32 digest = _hashReceipt(
            buyer,
            seller,
            creator,
            total,
            subTotal,
            deadline,
            servicePayout,
            creatorPayout,
            nonce.current(),
            new uint256[](amount),
            new uint256[](tokenId)
        );

        _verifySignature(digest, signature_);
        nonce.increment();

        _transact(paymentToken, buyer, seller, total);
        _transact(paymentToken, buyer, creatorPayoutAddr, creatorPayout);
        _transact(
            paymentToken,
            buyer,
            IGovernance(admin).treasury(),
            servicePayout
        );

        if (mint) {
            _mint(seller, tokenId, amount, "");
            emit TokenMinted(tokenId, creator);
        }
        _safeTransferFrom(seller, buyer, tokenId, amount, "");
        emit ItemSold(total, creatorPayout, seller, buyer, tokenId);
    }

    function _transact(
        address paymentToken,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (paymentToken == address(0)) {
            (bool success, bytes memory data) = payable(to).call{value: amount}(
                ""
            );
            require(success, "Marketplace#_transact: PAYMENT_FAILED");
        } else {
            IERC20(paymentToken).safeTransferFrom(from, to, amount);
        }
    }

    function uri(uint256 tokenId)
        public
        view
        override(ERC1155, ERC1155URIStorage)
        returns (string memory)
    {
        return ERC1155URIStorage.uri(tokenId);
    }

    function freezeUri() external {}

    function getVersion() external pure returns (bytes32) {
        return VERSION;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _verifySignature(
        bytes32 data_,
        bytes calldata signature_
    ) private view {
        address signer = ECDSA.recover(data_, signature_);
        address verifier = IGovernance(admin).verifier();
        require(
            verifier == signer,
            "Marketplace#_verifySignature: INVALID_SIGNER_OR_PARAMS"
        );
    }

    function _hashReceipt(
        address buyer,
        address seller,
        address creator,
        uint256 total,
        uint256 subTotal,
        uint256 deadline,
        uint256 serviceFee,
        uint256 creatorFee,
        uint256 currentNonce,
        uint256[] memory amounts,
        uint256[] memory tokenIds
    ) internal view returns (bytes32 digets) {
        digets = _hashTypedDataV4(
            keccak256(
                abi.encodePacked(
                    keccak256(
                        "Receipt(address buyer, adress seller, address creator, Item item, Payment, payment, Expiration expiration)"
                    ),
                    buyer,
                    seller,
                    creator,
                    _hashItems(amounts, tokenIds),
                    _hashPayment(subTotal, creatorFee, serviceFee, total),
                    _hashExpiration(currentNonce, deadline)
                )
            )
        );
    }

    function _hashItems(uint256[] memory amounts, uint256[] memory tokenIds)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    keccak256("Items(uint256[] amounts, uint256[] tokenIds[])"),
                    amounts,
                    tokenIds
                )
            );
    }

    function _hashPayment(
        uint256 subTotal,
        uint256 creatorFee,
        uint256 serviceFee,
        uint256 total
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "Payment(uint256 subTotal, uint256 creatorFee, uint256 serviceFee, uint256 total)"
                    ),
                    subTotal,
                    creatorFee,
                    serviceFee,
                    total
                )
            );
    }

    // constructor() payable override(Pausable, ReentrancyGuard) {}

    function initialize(address admin_, string calldata uri_)
        external
        override
    {}

    function getType() external view override returns (uint96) {}

    function buy(bytes calldata signature) external payable override {}

    function listItem(
        uint16 type_,
        uint40 supply_,
        uint40 id_,
        uint256 price_
    ) external override {}

    function unlistItem(uint256 id) external override {}

    function buyNft(uint256 id) external payable override {}

    function changeItemPrice(uint256 id, uint256 newPrice) external override {}
}
