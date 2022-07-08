// SPDX-License-Identifier: Unlisened
pragma solidity >=0.8.13;

import "../interfaces/IGovernance.sol";
import "./TokenIdGenerator.sol";

library ReceiptUtil {
    error InsufficientPayment();

    using TokenIdGenerator for uint256;

    struct Item {
        uint256 amount;
        uint256 tokenId;
        uint256 unitPrice;
        address nftContract;
    }

    struct Bulk {
        address nftContract;
        uint256[] amounts;
        uint256[] tokenIds;
        uint256[] unitPrices;
    }

    struct Payment {
        uint256 subTotal;
        uint256 creatorPayout;
        uint256 servicePayout;
        uint256 total;
    }

    struct Receipt {
        uint256 nonce;
        address buyer;
        address seller;
        address paymentToken;
        address creatorPayoutAddr;
        Payment payment;
        Item item;
    }

    struct BulkReceipt {
        uint256 nonce;
        address buyer;
        address seller;
        address paymentToken;
        address creatorPayoutAddr;
        Payment payment;
        Bulk bulk;
    }

    bytes32 private constant ITEM_TYPE_HASH =
        keccak256(
            "Item(uint256 amount, uint256 tokenId, uint256 unitPrice, address nftContract)"
        );
    bytes32 private constant BULK_TYPE_HASH =
        keccak256(
            "Bulk(address nftContract, uint256[] amounts, uint256[] tokenIds, uint256[] unitPrices)"
        );
    bytes32 private constant PAYMENT_TYPE_HASH =
        keccak256(
            "Payment(uint256 subTotal, uint256 creatorPayout, uint256 servicePayout, uint256 total)"
        );
    bytes32 private constant RECEIPT_TYPE_HASH =
        keccak256(
            "Receipt(uint256 nonce, address buyer, address seller, address paymentToken, address creatorPayoutAddr, Payment payment, Item item"
        );

    bytes32 private constant BULK_RECEIPT_TYPE_HASH =
        keccak256(
            "BulkReceipt(uint256 nonce, address buyer, address seller, address paymentToken, address creatorPayoutAddr, Payment payment, Bulk bulk"
        );

    function __getPayment(
        uint256 amount_,
        uint256 creatorFee_,
        uint256 serviceFee_,
        uint256 unitPrice_
    ) private pure returns (Payment memory payment) {
        payment.subTotal = amount_ * unitPrice_;
        payment.servicePayout = (payment.subTotal * serviceFee_) / 1e4;
        payment.creatorPayout = (payment.subTotal * creatorFee_) / 1e4;
        payment.total =
            payment.subTotal +
            payment.servicePayout +
            payment.creatorPayout;
    }

    function hash(Receipt memory receipt_) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    RECEIPT_TYPE_HASH,
                    receipt_.nonce,
                    receipt_.buyer,
                    receipt_.seller,
                    __hashPayment(receipt_.payment),
                    receipt_.creatorPayoutAddr,
                    __hashItem(receipt_.item)
                )
            );
    }

    function hash(BulkReceipt memory receipt_) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    RECEIPT_TYPE_HASH,
                    receipt_.nonce,
                    receipt_.buyer,
                    receipt_.seller,
                    __hashPayment(receipt_.payment),
                    receipt_.creatorPayoutAddr,
                    __hashBulk(receipt_.bulk)
                )
            );
    }

    function __hashItem(Item memory item_) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ITEM_TYPE_HASH,
                    item_.amount,
                    item_.tokenId,
                    item_.unitPrice,
                    item_.nftContract
                )
            );
    }

    function __hashBulk(Bulk memory bulk_) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    BULK_TYPE_HASH,
                    bulk_.nftContract,
                    //keccak256(abi.encodePacked(bulk_.amounts)),
                    bulk_.amounts,
                    keccak256(abi.encodePacked(bulk_.tokenIds)),
                    keccak256(abi.encodePacked(bulk_.unitPrices))
                )
            );
    }

    function __hashPayment(Payment memory payment_)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    PAYMENT_TYPE_HASH,
                    payment_.subTotal,
                    payment_.creatorPayout,
                    payment_.servicePayout,
                    payment_.total
                )
            );
    }

    function createReceipt(
        address buyer_,
        address seller_,
        address paymentToken_,
        address creatorPayoutAddr_,
        uint256 nonce_,
        uint256 serviceFee_,
        Item calldata item_
    ) internal view returns (Receipt memory receipt) {
        receipt.payment = __getPayment(
            item_.amount,
            item_.tokenId.getCreatorFee(),
            serviceFee_,
            item_.unitPrice
        );

        __isSufficientPayment(receipt.payment.total);

        receipt.item = item_;
        receipt.nonce = nonce_;
        receipt.buyer = buyer_;
        receipt.seller = seller_;
        receipt.paymentToken = paymentToken_;
        receipt.creatorPayoutAddr = creatorPayoutAddr_;
    }

    function createBulkReceipt(
        uint256 nonce_,
        uint256 serviceFee_,
        address buyer_,
        address seller_,
        address paymentToken_,
        address creatorPayoutAddr_,
        Bulk calldata bulk_
    ) internal view returns (BulkReceipt memory receipt) {
        for (uint256 i; i < bulk_.tokenIds.length; ) {
            Payment memory _payment = __getPayment(
                bulk_.amounts[i],
                bulk_.tokenIds[i].getCreatorFee(),
                serviceFee_,
                bulk_.unitPrices[i]
            );
            receipt.payment.subTotal += _payment.subTotal;
            receipt.payment.creatorPayout += _payment.creatorPayout;
            receipt.payment.servicePayout += _payment.servicePayout;
            receipt.payment.total += _payment.total;

            unchecked {
                ++i;
            }
        }

        __isSufficientPayment(receipt.payment.total);

        receipt.bulk = bulk_;
        receipt.nonce = nonce_;
        receipt.buyer = buyer_;
        receipt.seller = seller_;
        receipt.paymentToken = paymentToken_;
        receipt.creatorPayoutAddr = creatorPayoutAddr_;
    }

    function __isSufficientPayment(uint256 total_) private view {
        if (msg.value < total_) {
            revert InsufficientPayment();
        }
    }
}
