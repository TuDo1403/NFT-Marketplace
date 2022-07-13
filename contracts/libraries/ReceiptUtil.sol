// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

import "../interfaces/IGovernance.sol";
import "./TokenIdGenerator.sol";

library ReceiptUtil {
    using TokenIdGenerator for uint256;

    struct Header {
        uint256 nonce;
        uint256 ticketExpiration;
        address seller;
        address paymentToken;
        address creatorPayoutAddr;
    }

    struct Item {
        uint256 amount;
        uint256 tokenId;
        uint256 unitPrice;
        address nftContract;
        string tokenURI;
    }

    struct Bulk {
        address nftContract;
        uint256[] amounts;
        uint256[] tokenIds;
        uint256[] unitPrices;
        string[] tokenURIs;
    }

    struct Payment {
        uint256 subTotal;
        uint256 creatorPayout;
        uint256 servicePayout;
        uint256 total;
    }

    struct Receipt {
        Header header;
        Payment payment;
        Item item;
    }

    struct BulkReceipt {
        Header header;
        Payment payment;
        Bulk bulk;
    }

    bytes32 private constant HEADER_TYPE_HASH =
        keccak256(
            "Header(uint256 nonce, uint256 ticketExpiration, address seller, address paymentToken, address creatorPayoutAddr)"
        );

    bytes32 private constant ITEM_TYPE_HASH =
        keccak256(
            "Item(uint256 amount, uint256 tokenId, uint256 unitPrice, address nftContract, string tokenURI)"
        );
    bytes32 private constant BULK_TYPE_HASH =
        keccak256(
            "Bulk(address nftContract, uint256[] amounts, uint256[] tokenIds, uint256[] unitPrices, string[] tokenURIs)"
        );
    bytes32 private constant PAYMENT_TYPE_HASH =
        keccak256(
            "Payment(uint256 subTotal, uint256 creatorPayout, uint256 servicePayout, uint256 total)"
        );
    bytes32 private constant RECEIPT_TYPE_HASH =
        keccak256("Receipt(Header header, Payment payment, Item item");

    bytes32 private constant BULK_RECEIPT_TYPE_HASH =
        keccak256("BulkReceipt(Header header, Payment payment, Bulk bulk");

    function hash(Receipt calldata receipt_) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    RECEIPT_TYPE_HASH,
                    __hashHeader(receipt_.header),
                    __hashPayment(receipt_.payment),
                    __hashItem(receipt_.item)
                )
            );
    }

    function hash(BulkReceipt calldata receipt_)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    RECEIPT_TYPE_HASH,
                    __hashHeader(receipt_.header),
                    __hashPayment(receipt_.payment),
                    __hashBulk(receipt_.bulk)
                )
            );
    }

    function __hashHeader(Header memory header_)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    HEADER_TYPE_HASH,
                    header_.nonce,
                    header_.ticketExpiration,
                    header_.seller,
                    header_.paymentToken,
                    header_.creatorPayoutAddr
                )
            );
    }

    function __hashItem(Item calldata item_) private pure returns (bytes32) {
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
                    bulk_.amounts,
                    bulk_.tokenIds,
                    bulk_.unitPrices
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
}
