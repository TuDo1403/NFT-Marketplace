// SPDX-License-Identifier: Unlisened
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";

import "./MarketplaceBase.sol";
import "./interfaces/ICollectible1155.sol";

contract Marketplace1155 is
    MarketplaceBase,
    ICollectible1155,
    ERC1155SupplyUpgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155URIStorageUpgradeable
{
    using TokenIdGenerator for uint256;
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant TYPE = keccak256("ERC1155");

    bytes32 private constant BULK_TYPE_HASH =
        keccak256(
            "Bulk(uint256[] amounts, uint256[] tokenIds, uint256[] unitPrices)"
        );
    bytes32 private constant BULK_PAYMENT_TYPE_HASH =
        keccak256(
            "BulkPayment(uint256 total, uint256 subTotal, uint256 creatorPayout, uint256 servicePayout, address[] paymentTokens)"
        );
    bytes32 private constant BULK_RECEIPT_TYPE_HASH =
        keccak256(
            "BulkReceipt(uint256 deadline, uint256 nonce, address buyer, address seller, Bulk bulk, BulkPayment payment)"
        );

    modifier onlyCreator(uint256 tokenId_) {
        require(
            tokenId_.getTokenCreator() == _msgSender(),
            "ERC1155: ONLY_CREATOR_ALLOWED"
        );
        _;
    }

    modifier onlyCreatorOfBatch(uint256[] calldata tokenIds_) {
        address sender = _msgSender();
        for (uint256 i; i < tokenIds_.length; ) {
            address creator = tokenIds_[i].getTokenCreator();
            require(sender == creator, "ERC1155: ONLY_CREATOR_ALLOWED");
            unchecked {
                ++i;
            }
        }
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId_) {
        address creator = tokenId_.getTokenCreator();
        address sender = _msgSender();
        require(
            balanceOf(sender, tokenId_) > 0 ||
                isApprovedForAll(creator, sender),
            "ERC1155: ONLY_OWNER_ALLOWED"
        );
        _;
    }

    modifier onlyBatchOwner(uint256[] calldata tokenIds_) {
        address sender = _msgSender();
        for (uint256 i; i < tokenIds_.length; ) {
            uint256 tokenId = tokenIds_[i];
            address creator = tokenId.getTokenCreator();
            require(
                balanceOf(sender, tokenId) > 0 ||
                    isApprovedForAll(creator, sender),
                "ERC1155: ONLY_OWNER_ALLOWED"
            );
            unchecked {
                ++i;
            }
        }
        _;
    }

    modifier onlyMinted(uint256 tokenId) {
        require(exists(tokenId), "ERC1155: TOKEN_NOT_EXIST");
        _;
    }

    modifier whenBatchNotFrozen(uint256[] calldata tokenIds_) {
        for (uint256 i; i < tokenIds_.length; ) {
            require(!frozenTokens[tokenIds_[i]], "ERC1155: TOKEN_IS_FROZEN");
        }
        _;
    }

    constructor(
        uint256 serviceFee_,
        uint256 creatorFeeUB_,
        address admin_,
        address factory_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    )
        MarketplaceBase(
            serviceFee_,
            creatorFeeUB_,
            admin_,
            factory_,
            name_,
            symbol_
        )
    {
        __initialize(IGovernance(admin_).manager(), name_, symbol_, baseURI_);
        _disableInitializers();
    }

    function redeemBulk(
        uint256 deadline_,
        bytes calldata signature_,
        address seller_,
        address[] calldata paymentTokens_,
        address[] calldata creatorPayoutAddrs_,
        uint256[] calldata amounts_,
        uint256[] calldata unitPrices_,
        uint256[] calldata tokenIds_,
        string[] calldata tokenURIs_
    ) external payable override whenNotPaused whenNotExpired(deadline_) {
        address buyer = _msgSender();
        bytes memory data;
        // prevent stack too deep
        {
            address _admin = admin;

            (
                address[] memory creators,
                uint256[] memory subTotals,
                uint256[] memory creatorPayouts,
                uint256[] memory servicePayouts,
                BulkReceipt memory bulkReceipt
            ) = _createBulkReceipt(
                    _admin,
                    buyer,
                    seller_,
                    deadline_,
                    paymentTokens_,
                    amounts_,
                    tokenIds_,
                    unitPrices_
                );

            bytes32 hashedBulkReceipt = _hashBulkReceipt(bulkReceipt);
            _verifySignature(
                IGovernance(_admin).verifier(),
                hashedBulkReceipt,
                signature_
            );

            nonce.increment();

            uint256[] memory tokensToMint;
            uint256[] memory amountsToMint;
            uint256 counter;
            address treasury = IGovernance(_admin).treasury();
            for (uint256 i; i < paymentTokens_.length; ) {
                address paymentToken = paymentTokens_[i];
                _transact(paymentToken, buyer, seller_, subTotals[i]);
                _transact(
                    paymentToken,
                    buyer,
                    creatorPayoutAddrs_[i],
                    creatorPayouts[i]
                );
                _transact(paymentToken, buyer, treasury, servicePayouts[i]);

                uint256 tokenId = tokenIds_[i];
                uint256 amount = amounts_[i];

                bool minted = _isMintedBefore(
                    seller_,
                    creators[i],
                    tokenId,
                    amount
                );

                unchecked {
                    if (!minted) {
                        tokensToMint[counter] = tokenId;
                        amountsToMint[counter] = amount;
                        string memory tokenURI = tokenURIs_[i];
                        if (bytes(tokenURI).length != 0) {
                            _setURI(tokenId, tokenURI);
                        }
                        ++counter;
                    }
                    ++i;
                }
            }

            _mintBatch(seller_, tokensToMint, amountsToMint, data);
        }

        _safeBatchTransferFrom(seller_, buyer, tokenIds_, amounts_, data);
    }

    function initialize(
        address owner_,
        string calldata name_,
        string calldata symbol_,
        string calldata baseURI_
    ) external override initializer onlyFactory {
        __initialize(owner_, name_, symbol_, baseURI_);
    }

    function freezeToken(uint256 tokenId_)
        external
        override
        whenNotFrozen(tokenId_)
        onlyCreator(tokenId_)
    {
        _freezeToken(tokenId_);
    }

    function setBaseURI(string calldata baseURI_) external override onlyOwner {
        _setBaseURI(baseURI_);
    }

    function setTokenURI(uint256 tokenId_, string calldata tokenURI_)
        external
        override
        onlyCreator(tokenId_)
        whenNotFrozen(tokenId_)
    {
        _setURI(tokenId_, tokenURI_);
        _freezeToken(tokenId_);
    }

    function mint(uint256 tokenId_, uint256 amount_)
        external
        override
        onlyCreator(tokenId_)
        whenNotFrozen(tokenId_)
    {
        _supplyCheck(tokenId_, amount_);
        _mint(_msgSender(), tokenId_, amount_, "");
    }

    function mint(
        uint256 type_,
        uint256 creatorFee_,
        uint256 index_,
        uint256 supply_,
        uint256 amount_,
        string calldata tokenURI_
    ) external override onlyOwner {
        uint256 tokenId = _createTokenId(
            type_,
            creatorFee_,
            index_,
            supply_,
            owner()
        );
        _supplyCheck(tokenId, amount_);

        if (bytes(tokenURI_).length != 0) {
            _setURI(tokenId, tokenURI_);
        }
        _mint(owner(), tokenId, amount_, "");
    }

    function mintBatch(
        uint256[] calldata tokenIds_,
        uint256[] calldata amounts_
    )
        external
        override
        onlyCreatorOfBatch(tokenIds_)
        whenBatchNotFrozen(tokenIds_)
    {
        for (uint256 i; i < amounts_.length; ) {
            _supplyCheck(tokenIds_[i], amounts_[i]);
            unchecked {
                ++i;
            }
        }
        bytes memory data;
        _mintBatch(_msgSender(), tokenIds_, amounts_, data);
    }

    function mintBatch(
        uint256[] calldata types_,
        uint256[] calldata creatorFees_,
        uint256[] calldata indices_,
        uint256[] calldata supplies_,
        uint256[] calldata amounts_,
        string[] calldata tokenURIs_
    ) external override onlyOwner {
        require(
            types_.length == creatorFees_.length &&
                creatorFees_.length == indices_.length &&
                indices_.length == supplies_.length &&
                supplies_.length == amounts_.length &&
                amounts_.length == tokenURIs_.length,
            "ERC1155: ARRAY_LENGTH_MISMATCH"
        );
        uint256[] memory tokenIds = new uint256[](types_.length);
        address _owner = owner();
        for (uint256 i; i < types_.length; ) {
            string memory tokenURI = tokenURIs_[i];
            uint256 tokenId = _createTokenId(
                types_[i],
                creatorFees_[i],
                indices_[i],
                supplies_[i],
                _owner
            );
            tokenIds[i] = tokenId;
            _supplyCheck(tokenId, amounts_[i]);

            if (bytes(tokenURI).length != 0) {
                _setURI(tokenId, tokenURI);
            }
            unchecked {
                ++i;
            }
        }
        bytes memory data;
        _mintBatch(owner(), tokenIds, amounts_, data);
    }

    function getTokenURI(uint256 tokenId_)
        external
        view
        override
        returns (string memory)
    {
        string memory _uri = uri(tokenId_);
        return
            string(abi.encodePacked(bytes(_uri), bytes(tokenId_.toString())));
    }

    function getType() external pure override returns (string memory) {
        return string(abi.encodePacked(TYPE));
    }

    function uri(uint256 tokenId)
        public
        view
        override(ERC1155Upgradeable, ERC1155URIStorageUpgradeable)
        returns (string memory)
    {
        return ERC1155URIStorageUpgradeable.uri(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _transferToken(
        address from_,
        address to_,
        uint256 amount_,
        uint256 tokenId_
    ) internal override {
        _safeTransferFrom(from_, to_, tokenId_, amount_, "");
    }

    function _lazyMint(
        address to_,
        uint256 tokenId_,
        uint256 amount_,
        string calldata tokenURI_
    ) internal override {
        _mint(to_, tokenId_, amount_, "");
        _setURI(tokenId_, tokenURI_);
    }

    function _freezeToken(uint256 tokenId_) internal {
        frozenTokens[tokenId_] = true;
    }

    function _supplyCheck(uint256 tokenId_, uint256 amount_)
        internal
        view
        override
    {
        require(amount_ <= 2**32 - 1, "ERC1155: AMOUNT_>_2^32 - 1");
        uint256 maxSupply = tokenId_.getTokenMaxSupply();
        if (maxSupply != 0) {
            unchecked {
                require(
                    amount_ + totalSupply(tokenId_) <= maxSupply,
                    "ERC1155: MAXIMUM_ALLOCATION"
                );
            }
        }
    }

    function _isMintedBefore(
        address seller_,
        address creator_,
        uint256 tokenId_,
        uint256 amount_
    ) internal view override returns (bool minted) {
        if (seller_ != creator_) {
            // token must be minted before or seller must have token
            require(
                exists(tokenId_) || balanceOf(seller_, tokenId_) != 0,
                "ERC1155: INVALID_SELLER"
            );
            require(
                amount_ <= balanceOf(seller_, tokenId_),
                "ERC1155: AMOUNT_>_SELLER_BALANCE"
            );
            minted = true;
        } else {
            minted = false;
        }
    }

    function _createBulkReceipt(
        address admin_,
        address buyer_,
        address seller_,
        uint256 deadline_,
        address[] calldata paymentTokens_,
        uint256[] calldata amounts_,
        uint256[] calldata tokenIds_,
        uint256[] calldata unitPrices_
    )
        internal
        view
        returns (
            address[] memory creators,
            uint256[] memory subTotals,
            uint256[] memory creatorPayouts,
            uint256[] memory servicePayouts,
            BulkReceipt memory bulkReceipt
        )
    {
        uint256 total;
        uint256 subTotal;
        uint256 creatorPayout;
        uint256 servicePayout;
        for (uint256 i; i < tokenIds_.length; ) {
            uint256 tokenId = tokenIds_[i];
            uint256 amount = amounts_[i];

            _supplyCheck(tokenId, amount);
            require(
                _isPaymentSupported(admin_, paymentTokens_[i]),
                "ERC1155: PAYMENT_NOT_SUPPORTED"
            );

            uint256 creatorFee = tokenId.getCreatorFee();
            (
                uint256 _total,
                uint256 _subTotal,
                uint256 _creatorPayout,
                uint256 _servicePayout
            ) = _getPayment(amount, creatorFee, unitPrices_[i]);

            creators[i] = tokenId.getTokenCreator();
            creatorPayouts[i] = _creatorPayout;
            servicePayouts[i] = _servicePayout;
            subTotals[i] = _subTotal;

            total += _total;
            subTotal += _subTotal;
            creatorPayout += _creatorPayout;
            servicePayout += _servicePayout;

            unchecked {
                ++i;
            }
        }

        require(msg.value >= total, "ERC1155: INSUFFICIENT_PAYMENT");

        bulkReceipt = BulkReceipt(
            deadline_,
            nonce.current(),
            buyer_,
            seller_,
            Bulk(amounts_, tokenIds_, unitPrices_),
            BulkPayment(
                total,
                subTotal,
                creatorPayout,
                servicePayout,
                paymentTokens_
            )
        );
    }

    function _hashBulkReceipt(BulkReceipt memory bulkReceipt_)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encodePacked(
                        BULK_RECEIPT_TYPE_HASH,
                        bulkReceipt_.deadline,
                        bulkReceipt_.nonce,
                        bulkReceipt_.buyer,
                        bulkReceipt_.seller,
                        __hashBulk(
                            bulkReceipt_.bulk.amounts,
                            bulkReceipt_.bulk.tokenIds,
                            bulkReceipt_.bulk.unitPrices
                        ),
                        __hashBulkPayment(
                            bulkReceipt_.payment.total,
                            bulkReceipt_.payment.subTotal,
                            bulkReceipt_.payment.creatorPayout,
                            bulkReceipt_.payment.servicePayout,
                            bulkReceipt_.payment.paymentTokens
                        )
                    )
                )
            );
    }

    function __initialize(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) private {
        _setBaseURI(baseURI_);
        __ERC1155Supply_init();
        __ERC1155Burnable_init();
        __ERC1155URIStorage_init();
        super._initialize(owner_, name_, symbol_);
    }

    function __hashBulk(
        uint256[] memory amounts_,
        uint256[] memory tokenIds_,
        uint256[] memory unitPrices_
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    BULK_TYPE_HASH,
                    keccak256(abi.encodePacked(amounts_)),
                    keccak256(abi.encodePacked(tokenIds_)),
                    keccak256(abi.encodePacked(unitPrices_))
                )
            );
    }

    function __hashBulkPayment(
        uint256 total_,
        uint256 subTotal_,
        uint256 creatorPayout_,
        uint256 servicePayout_,
        address[] memory paymentTokens_
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    BULK_PAYMENT_TYPE_HASH,
                    total_,
                    subTotal_,
                    creatorPayout_,
                    servicePayout_,
                    keccak256(abi.encodePacked(paymentTokens_))
                )
            );
    }
}
