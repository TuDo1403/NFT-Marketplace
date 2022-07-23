// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
//import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import "./base/NFTBase.sol";
import "./base/MarketplaceIntegratable.sol";

import "./interfaces/INFT.sol";
import "./interfaces/ISemiNFT.sol";
import "./interfaces/IMarketplace.sol";

import "./base/token/ERC1155/IERC1155Lite.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./base/token/ERC721/extensions/IERC721Permit.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./base/token/ERC1155/extensions/IERC1155Permit.sol";

import "./libraries/ReceiptUtil.sol";

contract Marketplace is
    IMarketplace,
    EIP712Upgradeable,
    PausableUpgradeable,
    MarketplaceIntegratable,
    ReentrancyGuardUpgradeable
{
    using ReceiptUtil for ReceiptUtil.Receipt;
    using ReceiptUtil for ReceiptUtil.BulkReceipt;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    //keccak256("Marketplace_v1")
    bytes32 public constant VERSION =
        0x58166ef1331604f9d1096f21021b62681af867d090bf7bef436de91286e1ed67;

    uint256 public serviceFeeNumerator;

    mapping(address => CountersUpgradeable.Counter) public nonces;

    // 2521470
    function initialize(address admin_, uint256 serviceFeeRightShiftBit_)
        external
        initializer
    {
        _initialize(admin_, serviceFeeRightShiftBit_);
    }

    // receive() external payable {
    //     emit Received(_msgSender(), msg.value, "Received Token");
    // }

    //fallback() external payable {}

    // function kill() external onlyManager {
    //     selfdestruct(payable(IGovernance(admin).treasury()));
    // }

    function redeem(
        ReceiptUtil.Receipt calldata receipt_,
        bytes calldata signature_
    ) external payable override whenNotPaused nonReentrant {
        IGovernance _admin = admin;
        ReceiptUtil.Item memory item = receipt_.item;
        uint256 salePrice = item.amount * item.unitPrice;
        ReceiptUtil.Header memory header = receipt_.header;
        ReceiptUtil.verifyReceipt(
            _admin,
            header.paymentToken,
            salePrice,
            receipt_.deadline,
            _hashTypedDataV4(receipt_.hash()),
            signature_
        );

        address sellerAddr = header.seller.addr;
        nonces[sellerAddr].increment();

        uint256 tokenId = item.tokenId;
        address buyerAddr = header.buyer.addr;
        address nftContract = header.nftContract;
        //address paymentToken = header.paymentToken;
        {
            ReceiptUtil.User memory buyer = header.buyer;
            if (buyer.v != 0) {
                IERC20PermitUpgradeable(header.paymentToken).permit(
                    buyerAddr,
                    address(this),
                    salePrice,
                    buyer.deadline,
                    buyer.v,
                    buyer.r,
                    buyer.s
                );
            }

            bool tokenExists = _pay(
                buyerAddr,
                _admin.treasury(),
                sellerAddr,
                nftContract,
                header.paymentToken,
                serviceFeeNumerator,
                tokenId,
                salePrice
            );
            if (!tokenExists) {
                INFT(nftContract).mint(
                    sellerAddr,
                    tokenId,
                    item.amount,
                    item.tokenURI
                );
            }
        }

        _safeTransferFrom(
            address(this),
            buyerAddr,
            sellerAddr,
            nftContract,
            tokenId,
            item.amount,
            header.seller
        );

        emit ItemRedeemed(
            nftContract,
            buyerAddr,
            tokenId,
            header.paymentToken,
            salePrice
        );
    }

    function redeemBulk(
        ReceiptUtil.BulkReceipt calldata receipt_,
        bytes calldata signature_
    ) external payable override whenNotPaused nonReentrant {
        uint256 salePrice;
        ReceiptUtil.Bulk memory bulk = receipt_.bulk;
        for (uint256 i; i < bulk.amounts.length; ) {
            salePrice += bulk.amounts[i] * bulk.unitPrices[i];
            unchecked {
                ++i;
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
        address buyerAdrr;
        address thisAddr = address(this);
        {
            ReceiptUtil.User memory buyer = header.buyer;
            buyerAdrr = buyer.addr;
            if (buyer.v != 0) {
                IERC20PermitUpgradeable(header.paymentToken).permit(
                    buyerAdrr,
                    thisAddr,
                    salePrice,
                    buyer.deadline,
                    buyer.v,
                    buyer.r,
                    buyer.s
                );
            }
        }

        address nftContract = header.nftContract;
        _batchProcess(
            _admin.treasury(),
            buyerAdrr,
            sellerAddr,
            nftContract,
            header.paymentToken,
            salePrice,
            bulk
        );
        IERC1155Permit(nftContract).permit(
            seller.deadline,
            sellerAddr,
            thisAddr,
            seller.v,
            seller.r,
            seller.s
        );
        IERC1155(nftContract).safeBatchTransferFrom(
            sellerAddr,
            buyerAdrr,
            bulk.tokenIds,
            bulk.amounts,
            ""
        );

        emit BulkRedeemed(
            nftContract,
            buyerAdrr,
            bulk.tokenIds,
            header.paymentToken,
            salePrice
        );
    }

    function pause() external override whenNotPaused {
        _onlyManager();
        _pause();
    }

    function unpause() external override whenPaused {
        _onlyManager();
        _unpause();
    }

    function _safeTransferFrom(
        address spender_,
        address buyerAddr_,
        address sellerAddr_,
        address nftContract_,
        uint256 tokenId_,
        uint256 amount_,
        ReceiptUtil.User memory seller_
    ) internal {
        if (INFTBase(nftContract_).TYPE() != 721) {
            IERC1155Permit(nftContract_).permit(
                seller_.deadline,
                sellerAddr_,
                spender_,
                seller_.v,
                seller_.r,
                seller_.s
            );

            IERC1155(nftContract_).safeTransferFrom(
                sellerAddr_,
                buyerAddr_,
                tokenId_,
                amount_,
                ""
            );
        } else {
            IERC721Permit(nftContract_).permit(
                tokenId_,
                seller_.deadline,
                spender_,
                seller_.v,
                seller_.r,
                seller_.s
            );

            IERC721(nftContract_).safeTransferFrom(
                sellerAddr_,
                buyerAddr_,
                tokenId_,
                ""
            );
        }
    }

    function _batchProcess(
        address treasury_,
        address buyerAddr_,
        address sellerAddr_,
        address nftContract_,
        address paymentToken_,
        uint256 salePrice_,
        ReceiptUtil.Bulk memory bulk_
    ) internal {
        uint256 counter;
        ReceiptUtil.Bulk memory bulkToMint;
        {
            uint256 _serviceFeeNumerator = serviceFeeNumerator;
            for (uint256 i; i < bulk_.amounts.length; ) {
                uint256 tokenId = bulk_.tokenIds[i];
                bool _tokenExists = _pay(
                    buyerAddr_,
                    treasury_,
                    sellerAddr_,
                    nftContract_,
                    paymentToken_,
                    _serviceFeeNumerator,
                    tokenId,
                    salePrice_
                );
                unchecked {
                    if (!_tokenExists) {
                        bulkToMint.tokenIds[counter] = tokenId;
                        bulkToMint.amounts[counter] = bulk_.amounts[i];
                        bulkToMint.tokenURIs[counter] = bulk_.tokenURIs[i];
                        ++counter;
                    }
                    ++i;
                }
            }
        }

        if (counter != 0) {
            ISemiNFT(nftContract_).mintBatch(
                sellerAddr_,
                bulkToMint.tokenIds,
                bulkToMint.amounts,
                bulkToMint.tokenURIs
            );
        }
    }

    function _pay(
        address buyerAddr_,
        address treasury_,
        address sellerAddr_,
        address nftContract_,
        address paymentToken_,
        uint256 serviceFeeNumerator_,
        uint256 tokenId_,
        uint256 salePrice_
    ) internal virtual returns (bool) {
        uint256 royaltyAmount;
        {
            address receiver;
            (receiver, royaltyAmount) = IERC2981Upgradeable(nftContract_)
                .royaltyInfo(tokenId_, salePrice_);
            _transact(paymentToken_, buyerAddr_, receiver, royaltyAmount);
        }
        // uint256 serviceAmount = salePrice_ >> serviceFeeRightShiftBit_;
        //console.log(serviceFeeRightShiftBit_);
        // uint256 serviceAmount;
        // assembly {
        //     serviceAmount := shr(serviceFeeRightShiftBit_, salePrice_)
        // }

        unchecked {
            // uint256 serviceAmount = salePrice_ >> serviceFeeNumerator_;
            uint256 serviceAmount = (serviceFeeNumerator_ * salePrice_) / _feeDenominator();
            _transact(paymentToken_, buyerAddr_, treasury_, serviceAmount);
            _transact(
                paymentToken_,
                buyerAddr_,
                sellerAddr_,
                salePrice_ - royaltyAmount - serviceAmount
            );
        }

        return royaltyAmount != 0;
    }

    function _feeDenominator() internal pure returns (uint16) {
        return 1e4;
    }

    function _transact(
        address paymentToken_,
        address from_,
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
            IERC20Upgradeable(paymentToken_).safeTransferFrom(
                from_,
                to_,
                amount_
            );
        }
    }

    function _initialize(address admin_, uint256 serviceFeeNumerator_)
        internal
        virtual
        onlyInitializing
    {
        serviceFeeNumerator = serviceFeeNumerator_ % 1e3;
        _initialize(admin_);

        __Pausable_init();
        __ReentrancyGuard_init();
        __EIP712_init(type(Marketplace).name, "v1");
    }
}
