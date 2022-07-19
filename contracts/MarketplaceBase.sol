// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import "./base/MarketplaceIntegratable.sol";
import "./base/NFTBase.sol";

import "./interfaces/IMarketplace.sol";
import "./interfaces/INFT.sol";
import "./interfaces/ISemiNFT.sol";
import "./base/token/ERC721/extensions/IERC721Permit.sol";
import "./base/token/ERC1155/extensions/IERC1155Permit.sol";

contract MarketplaceBase is
    IMarketplace,
    EIP712Upgradeable,
    PausableUpgradeable,
    MarketplaceIntegratable,
    ReentrancyGuardUpgradeable
{
    //using Strings for uint256;
    using TokenIdGenerator for uint256;
    using ReceiptUtil for ReceiptUtil.Receipt;
    using ReceiptUtil for ReceiptUtil.BulkReceipt;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    uint256 public serviceFee;
    uint256 public creatorFeeUB; // creator fee upper bound

    string public constant VERSION = "1";
    string public constant NAME = "Marketplace";

    mapping(address => CountersUpgradeable.Counter) public nonces;

    constructor(
        address admin_,
        uint256 serviceFee_,
        uint256 creatorFeeUB_
    ) MarketplaceIntegratable(admin_) initializer {
        __initialize(serviceFee_, creatorFeeUB_);
    }

    // 2521470
    function initialize(
        uint256 serviceFee_,
        uint256 creatorFeeUB_ // Pausable() // ReentrancyGuard()
    ) external initializer {
        __initialize(serviceFee_, creatorFeeUB_);
    }

    // receive() external payable {
    //     emit Received(_msgSender(), msg.value, "Received Token");
    // }

    //fallback() external payable {}

    // function kill() external onlyManager {
    //     selfdestruct(payable(IGovernance(admin).treasury()));
    // }

    function multiDelegatecall(bytes[] calldata data)
        external
        payable
        override
        onlyManager(_msgSender())
        whenNotPaused
        returns (bytes[] memory results)
    {
        for (uint256 i; i < data.length; ) {
            (bool ok, bytes memory result) = address(this).delegatecall(
                data[i]
            );
            if (!ok) {
                revert MP__ExecutionFailed();
            }
            results[i] = result;
            unchecked {
                ++i;
            }
        }
    }

    function redeem(
        ReceiptUtil.Receipt calldata receipt_,
        bytes calldata signature_
    ) external payable override whenNotPaused nonReentrant {
        IGovernance _admin = admin;
        ReceiptUtil.Item memory item = receipt_.item;
        ReceiptUtil.Header memory header = receipt_.header;
        uint256 salePrice = item.amount * item.unitPrice;

        // console.log("-------------Receipt--------------");
        // console.log("------------Header-------------");
        // console.log("------Buyer------");
        // console.log(receipt_.header.buyer.addr);
        // console.log(receipt_.header.buyer.v);
        // console.log(receipt_.header.buyer.deadline);
        // console.logBytes32(receipt_.header.buyer.r);
        // console.logBytes32(receipt_.header.buyer.s);
        // console.log("------Seller------");
        // console.log(receipt_.header.seller.addr);
        // console.log(receipt_.header.seller.v);
        // console.log(receipt_.header.seller.deadline);
        // console.logBytes32(receipt_.header.seller.r);
        // console.logBytes32(receipt_.header.seller.s);
        // console.log("---NftContract----");
        // console.log(receipt_.header.nftContract);
        // console.log("---PaymentToken---");
        // console.log(receipt_.header.paymentToken);
        // console.log("-------------Item--------------");
        // console.log(receipt_.item.amount);
        // console.log(receipt_.item.tokenId);
        // console.log(receipt_.item.unitPrice);
        // console.log(receipt_.item.tokenURI);
        // console.log("-------------nonce-------------");
        // console.log(receipt_.nonce);
        // console.log("------------deadline-----------");
        // console.log(receipt_.deadline);
        // console.log("receipt hash: ");
        // console.logBytes32(receipt_.hash());
        console.logBytes(signature_);
        ReceiptUtil.verifyReceipt(
            _admin,
            header.paymentToken,
            salePrice,
            receipt_.deadline,
            _hashTypedDataV4(receipt_.hash()),
            signature_
        );

        address nftContract = header.nftContract;
        address sellerAddr = header.seller.addr;
        nonces[sellerAddr].increment();

        {
            //address spender = address(this);
            bool tokenExists = _pay(
                address(this),
                _admin.treasury(),
                salePrice,
                serviceFee,
                header,
                item
            );
            if (!tokenExists) {
                INFT(nftContract).mint(sellerAddr, item);
            }
        }

        _safeTransferFrom(
            address(this),
            header.buyer.addr,
            nftContract,
            item,
            header.seller
        );

        emit ItemRedeemed(
            nftContract,
            header.buyer.addr,
            item.tokenId,
            header.paymentToken,
            salePrice
        );
    }

    function redeemBulk(
        ReceiptUtil.BulkReceipt calldata receipt_,
        bytes calldata signature_
    ) external payable whenNotPaused nonReentrant {
        uint256 salePrice;
        ReceiptUtil.Bulk memory bulk = receipt_.bulk;
        uint256[] memory amounts;
        uint256 length;
        {
            amounts = bulk.amounts;
            length = amounts.length;
            uint256[] memory unitPrices = bulk.unitPrices;
            for (uint256 i; i < length; ) {
                salePrice += amounts[i] * unitPrices[i];
                unchecked {
                    ++i;
                }
            }
        }

        IGovernance _admin = admin;
        ReceiptUtil.Header memory header = receipt_.header;

        ReceiptUtil.verifyReceipt(
            _admin,
            header.paymentToken,
            salePrice,
            receipt_.deadline,
            _hashTypedDataV4(receipt_.hash()),
            signature_
        );
        ReceiptUtil.User memory seller = header.seller;
        address sellerAddr = seller.addr;
        nonces[sellerAddr].increment();

        _batchProcess(_admin.treasury(), salePrice, length, bulk, header);
        address nftContract = header.nftContract;
        IERC1155Permit(nftContract).permit(
            seller.deadline,
            sellerAddr,
            address(this),
            seller.v,
            seller.r,
            seller.s
        );
        IERC1155(nftContract).safeBatchTransferFrom(
            sellerAddr,
            header.buyer.addr,
            bulk.tokenIds,
            amounts,
            ""
        );

        emit BulkRedeemed(
            nftContract,
            header.buyer.addr,
            bulk.tokenIds,
            header.paymentToken,
            salePrice
        );
    }

    // function redeemBulk(
    //     ReceiptUtil.BulkReceipt calldata receipt_,
    //     bytes calldata signature_
    // ) external payable override whenNotPaused nonReentrant {
    //     ReceiptUtil.Header memory header = receipt_.header;
    //     ReceiptUtil.verifyReceipt(
    //         admin,
    //         header,
    //         _hashTypedDataV4(receipt_.hash()),
    //         signature_
    //     );

    //     address seller = header.seller;
    //     nonces[seller].increment();
    //     ReceiptUtil.Bulk memory bulk = receipt_.bulk;
    //     address nftContract = bulk.nftContract;
    //     // IERC1155Permit(nftContract).permit(
    //     //     seller, address(this),
    //     // );
    //     {
    //         uint256[] memory tokensToMint;
    //         uint256[] memory amountsToMint;
    //         // get rid of stack too deep

    //         {
    //             uint256 counter;
    //             for (uint256 i; i < bulk.tokenIds.length; ) {
    //                 uint256 tokenId = bulk.tokenIds[i];
    //                 uint256 amount = bulk.amounts[i];
    //                 bool minted = ICollectible(nftContract).isMintedBefore(
    //                     seller,
    //                     tokenId,
    //                     amount
    //                 );

    //                 unchecked {
    //                     if (!minted) {
    //                         tokensToMint[counter] = tokenId;
    //                         amountsToMint[counter] = amount;
    //                         ++counter;
    //                     }
    //                     ++i;
    //                 }
    //             }
    //         }

    //         ICollectible1155(nftContract).mintBatch(
    //             seller,
    //             tokensToMint,
    //             amountsToMint,
    //             bulk.tokenURIs
    //         );
    //     }

    //     {
    //         address buyer = _msgSender();
    //         address paymentToken = header.paymentToken;
    //         _makePayment(false, buyer, seller, paymentToken, receipt_.payment);

    //         IERC1155(nftContract).safeBatchTransferFrom(
    //             seller,
    //             buyer,
    //             bulk.tokenIds,
    //             bulk.amounts,
    //             ""
    //         );

    //         emit BulkRedeemed(
    //             nftContract,
    //             buyer,
    //             bulk.tokenIds,
    //             paymentToken,
    //             bulk.unitPrices,
    //             header.total
    //         );
    //     }
    // }

    function pause() external override whenNotPaused onlyManager(_msgSender()) {
        _pause();
    }

    function unpause() external override whenPaused onlyManager(_msgSender()) {
        _unpause();
    }

    function _safeTransferFrom(
        address spender_,
        address buyerAddr_,
        address nftContract_,
        ReceiptUtil.Item memory item_,
        ReceiptUtil.User memory seller_
    ) internal {
        if (INFTBase(nftContract_).TYPE() != 721) {
            IERC1155Permit(nftContract_).permit(
                seller_.deadline,
                seller_.addr,
                spender_,
                seller_.v,
                seller_.r,
                seller_.s
            );

            IERC1155(nftContract_).safeTransferFrom(
                seller_.addr,
                buyerAddr_,
                item_.tokenId,
                item_.amount,
                ""
            );
        } else {
            IERC721Permit(nftContract_).permit(
                item_.tokenId,
                seller_.deadline,
                spender_,
                seller_.v,
                seller_.r,
                seller_.s
            );

            IERC721(nftContract_).safeTransferFrom(
                seller_.addr,
                buyerAddr_,
                item_.tokenId,
                ""
            );
        }
    }

    function _batchProcess(
        address treasury_,
        uint256 salePrice_,
        uint256 arrLength_,
        ReceiptUtil.Bulk memory bulk_,
        ReceiptUtil.Header memory header_
    ) internal {
        uint256 counter;
        ReceiptUtil.Bulk memory bulkToMint;
        {
            address spender = address(this);
            uint256 _serviceFee = serviceFee;
            for (uint256 i; i < arrLength_; ) {
                uint256 amount = bulk_.amounts[i];
                uint256 tokenId = bulk_.tokenIds[i];
                bool _tokenExists = _pay(
                    spender,
                    treasury_,
                    salePrice_,
                    _serviceFee,
                    header_,
                    ReceiptUtil.Item(amount, tokenId, 0, "")
                );
                unchecked {
                    if (_tokenExists) {
                        bulkToMint.tokenIds[counter] = tokenId;
                        bulkToMint.amounts[counter] = amount;
                        bulkToMint.tokenURIs[counter] = bulk_.tokenURIs[i];
                        ++counter;
                    }
                    ++i;
                }
            }
        }

        if (counter != 0) {
            ISemiNFT(header_.nftContract).mintBatch(
                header_.seller.addr,
                bulkToMint
            );
        }
    }

    function _pay(
        address spender_,
        address treasury_,
        uint256 salePrice_,
        uint256 serviceFraction_,
        ReceiptUtil.Header memory header_,
        ReceiptUtil.Item memory item_
    ) internal virtual returns (bool) {
        uint256 royaltyAmount;
        {
            address paymentToken = header_.paymentToken;
            ReceiptUtil.User memory buyer = header_.buyer;
            {
                address receiver;
                (receiver, royaltyAmount) = IERC2981Upgradeable(
                    header_.nftContract
                ).royaltyInfo(item_.tokenId, salePrice_);
                _transact(
                    spender_,
                    paymentToken,
                    buyer,
                    receiver,
                    royaltyAmount
                );
            }
            {
                uint256 serviceAmount = (serviceFraction_ * salePrice_) /
                    _feeDominator();
                _transact(
                    spender_,
                    paymentToken,
                    buyer,
                    treasury_,
                    serviceAmount
                );
                _transact(
                    spender_,
                    paymentToken,
                    buyer,
                    header_.seller.addr,
                    salePrice_ - royaltyAmount - serviceAmount
                );
            }
        }
        return royaltyAmount != 0;
    }

    function _feeDominator() internal pure virtual returns (uint256) {
        return 1e4;
    }

    function _transact(
        address spender_,
        address paymentToken_,
        ReceiptUtil.User memory from_,
        address to_,
        uint256 amount_
    ) internal virtual {
        if (amount_ == 0) return;
        if (paymentToken_ == address(0)) {
            (bool ok, ) = payable(to_).call{value: amount_}("");
            if (!ok) {
                revert MP__PaymentFailed();
            }
        } else {
            if (from_.v != 0) {
                IERC20PermitUpgradeable(paymentToken_).permit(
                    from_.addr,
                    spender_,
                    amount_,
                    from_.deadline,
                    from_.v,
                    from_.r,
                    from_.s
                );
            }
            IERC20Upgradeable(paymentToken_).safeTransferFrom(
                from_.addr,
                to_,
                amount_
            );
        }
    }

    function __initialize(uint256 serviceFee_, uint256 creatorFeeUB_) private {
        if (serviceFee_ != 0) {
            serviceFee = serviceFee_ % 1e4;
        }
        if (creatorFeeUB_ != 0) {
            creatorFeeUB = creatorFeeUB_ % 1e4;
        }

        __Pausable_init();
        __ReentrancyGuard_init();
        __EIP712_init(NAME, VERSION);
    }
}
