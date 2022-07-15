// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import "./interfaces/IMarketplace.sol";
import "./interfaces/ICollectible.sol";
import "./interfaces/ICollectible1155.sol";

contract MarketplaceBase is
    IMarketplace,
    EIP712Upgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using Strings for uint256;
    using TokenIdGenerator for uint256;
    using ReceiptUtil for ReceiptUtil.Receipt;
    using ReceiptUtil for ReceiptUtil.BulkReceipt;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    IGovernance public immutable admin;

    uint256 public serviceFee;
    uint256 public creatorFeeUB; // creator fee upper bound

    uint256 public constant VERSION = 1;
    string public constant NAME = "Marketplace";

    CountersUpgradeable.Counter public nonce;

    modifier onlyManager() {
        if (_msgSender() != admin.manager()) {
            revert MP__Unauthorized();
        }
        _;
    }

    constructor(
        address admin_,
        uint256 serviceFee_,
        uint256 creatorFeeUB_
    ) initializer {
        admin = IGovernance(admin_);
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
        onlyManager
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
        uint256 deadline_,
        ReceiptUtil.Receipt calldata receipt_,
        bytes calldata signature_
    ) external payable override whenNotPaused nonReentrant {
        ReceiptUtil.Payment memory payment = receipt_.payment;
        ReceiptUtil.verifyReceipt(
            deadline_,
            _hashTypedDataV4(receipt_.hash()),
            admin,
            receipt_.header,
            payment,
            signature_
        );

        uint256 tokenId = receipt_.item.tokenId;
        address nftContract = receipt_.item.nftContract;

        address seller = receipt_.header.seller;
        uint256 amount = receipt_.item.amount;
        address buyer = _msgSender();
        address paymentToken = receipt_.header.paymentToken;
        {
            bool minted = ICollectible(nftContract).isMintedBefore(
                seller,
                tokenId,
                amount
            );
            _makePayment(
                minted,
                buyer,
                seller,
                paymentToken,
                receipt_.header.creatorPayoutAddr,
                payment
            );

            if (!minted) {
                ICollectible(nftContract).mint(
                    seller,
                    tokenId,
                    amount,
                    receipt_.item.tokenURI
                );
            }
        }
        ICollectible(nftContract).transferSingle(
            seller,
            buyer,
            amount,
            tokenId
        );

        emit ItemRedeemed(
            nftContract,
            buyer,
            tokenId,
            paymentToken,
            receipt_.item.unitPrice,
            payment.total
        );
    }

    function redeemBulk(
        uint256 deadline_,
        ReceiptUtil.BulkReceipt calldata receipt_,
        bytes calldata signature_
    ) external payable override whenNotPaused nonReentrant {
        ReceiptUtil.Payment memory payment = receipt_.payment;
        ReceiptUtil.verifyReceipt(
            deadline_,
            _hashTypedDataV4(receipt_.hash()),
            admin,
            receipt_.header,
            payment,
            signature_
        );

        address seller = receipt_.header.seller;
        address nftContract = receipt_.bulk.nftContract;
        {
            uint256[] memory tokensToMint;
            uint256[] memory amountsToMint;
            // get rid of stack too deep
            {
                uint256 counter;

                for (uint256 i; i < receipt_.bulk.tokenIds.length; ) {
                    uint256 tokenId = receipt_.bulk.tokenIds[i];
                    uint256 amount = receipt_.bulk.amounts[i];
                    bool minted = ICollectible(nftContract).isMintedBefore(
                        seller,
                        tokenId,
                        amount
                    );

                    unchecked {
                        if (!minted) {
                            tokensToMint[counter] = tokenId;
                            amountsToMint[counter] = amount;
                            ++counter;
                        }
                        ++i;
                    }
                }
            }

            ICollectible1155(nftContract).mintBatch(
                seller,
                tokensToMint,
                amountsToMint,
                receipt_.bulk.tokenURIs
            );
        }

        {
            address buyer = _msgSender();
            address paymentToken = receipt_.header.paymentToken;
            _makePayment(
                false,
                buyer,
                seller,
                paymentToken,
                receipt_.header.creatorPayoutAddr,
                payment
                // receipt_.payment.subTotal,
                // receipt_.payment.creatorPayout,
                // receipt_.payment.servicePayout
            );

            ICollectible1155(nftContract).transferBatch(
                seller,
                buyer,
                receipt_.bulk.tokenIds,
                receipt_.bulk.amounts
            );

            emit BulkRedeemed(
                nftContract,
                buyer,
                receipt_.bulk.tokenIds,
                paymentToken,
                receipt_.bulk.unitPrices,
                receipt_.payment.total
            );
        }
    }

    function pause() external override whenNotPaused onlyManager {
        _pause();
    }

    function unpause() external override whenPaused onlyManager {
        _unpause();
    }

    function _makePayment(
        bool minted_,
        address buyer_,
        address seller_,
        address paymentToken_,
        address creatorPayoutAddr_,
        ReceiptUtil.Payment memory payment_ // uint256 subTotal_,
    ) internal virtual // uint256 creatorPayout_,
    // uint256 servicePayout_
    {
        _transact(paymentToken_, buyer_, seller_, payment_.subTotal);
        _transact(
            paymentToken_,
            buyer_,
            admin.treasury(),
            payment_.servicePayout
        );
        if (minted_) {
            _transact(
                paymentToken_,
                buyer_,
                creatorPayoutAddr_,
                payment_.creatorPayout
            );
        }
    }

    function _transact(
        address paymentToken_,
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual {
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

    function __initialize(uint256 serviceFee_, uint256 creatorFeeUB_) private {
        if (serviceFee_ != 0) {
            serviceFee = serviceFee_ % 1e4;
        }
        if (creatorFeeUB_ != 0) {
            creatorFeeUB = creatorFeeUB_ % 1e4;
        }

        __Pausable_init();
        __ReentrancyGuard_init();
        __EIP712_init(NAME, VERSION.toString());
    }
}
