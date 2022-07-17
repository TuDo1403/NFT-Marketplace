// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "../interfaces/IGovernance.sol";
import "./TokenIdGenerator.sol";

library ReceiptUtil {
    error RU__Expired();
    error RU__InvalidSignature();
    error RU__PaymentUnsuported();
    error RU__InsufficientPayment();

    using TokenIdGenerator for uint256;

    struct User {
        address addr;
        uint8 v;
        uint256 deadline;
        bytes32 r;
        bytes32 s;
    }

    struct Header {
        User buyer;
        User seller;
        address nftContract;
        address paymentToken;
    }

    struct Item {
        uint256 amount;
        uint256 tokenId;
        uint256 unitPrice;
        string tokenURI;
    }

    struct Bulk {
        uint256[] amounts;
        uint256[] tokenIds;
        uint256[] unitPrices;
        string[] tokenURIs;
    }

    struct Receipt {
        Header header;
        Item item;
        uint256 nonce;
        uint256 deadline;
    }

    struct BulkReceipt {
        Header header;
        Bulk bulk;
        uint256 nonce;
        uint256 deadline;
    }

    ///@dev Value is equal to keccak256("Header(User buyer,User seller,address nftContract,address paymentToken)User(address addr,uint8 v,uint256 deadline,bytes32 r,bytes32 s)User(address addr,uint8 v,uint256 deadline,bytes32 r,bytes32 s)")
    bytes32 private constant HEADER_TYPE_HASH =
        keccak256(
            "Header(User buyer,User seller,address nftContract,address paymentToken)User(address addr,uint8 v,uint256 deadline,bytes32 r,bytes32 s)User(address addr,uint8 v,uint256 deadline,bytes32 r,bytes32 s)"
        );

    ///@dev Value is equal to keccak256("Item(uint256 amount,uint256 tokenId,uint256 unitPrice,string tokenURI)")
    bytes32 private constant ITEM_TYPE_HASH =
        keccak256(
            "Item(uint256 amount,uint256 tokenId,uint256 unitPrice,string tokenURI)"
        );

    ///@dev Value is equal to keccak256("Bulk(uint256[] amounts,uint256[] tokenIds,uint256[] unitPrices,string[] tokenURIs)")
    bytes32 private constant BULK_TYPE_HASH =
        keccak256(
            "Bulk(uint256[] amounts,uint256[] tokenIds,uint256[] unitPrices,string[] tokenURIs)"
        );

    bytes32 private constant PAYMENT_TYPE_HASH =
        keccak256(
            "Payment(uint256 subTotal,uint256 creatorPayout,uint256 servicePayout,uint256 total)"
        );

    ///@dev value is equal to keccak256("Receipt(Header header,Item item,uint256 nonce,uint256 deadline)Header(User buyer,User seller,address nftContract,address paymentToken)Item(uint256 amount,uint256 tokenId,uint256 unitPrice,string tokenURI)User(address addr,uint8 v,uint256 dealdine,bytes32 r,bytes32 s)User(address addr,uint8 v,uint256 deadline,bytes32 r,bytes32 s)")
    bytes32 private constant RECEIPT_TYPE_HASH =
        keccak256(
            "Receipt(Header header,Item item,uint256 nonce,uint256 deadline)Header(User buyer,User seller,address nftContract,address paymentToken)Item(uint256 amount,uint256 tokenId,uint256 unitPrice,string tokenURI)User(address addr,uint8 v,uint256 dealdine,bytes32 r,bytes32 s)User(address addr,uint8 v,uint256 deadline,bytes32 r,bytes32 s)"
        );

    ///@dev value is equal to keccak256("BulkReceipt(Header header,Bulk bulk,uint256 nonce,uint256 deadline)Header(User buyer,User seller,address nftContract,address paymentToken)IBulk(uint256[] amounts,uint256[] tokenIds,uint256[] unitPrices,string[] tokenURIs)User(address addr,uint8 v,uint256 dealdine,bytes32 r,bytes32 s)User(address addr,uint8 v,uint256 deadline,bytes32 r,bytes32 s)")
    bytes32 private constant BULK_RECEIPT_TYPE_HASH =
        keccak256(
            "BulkReceipt(Header header,Bulk bulk,uint256 nonce,uint256 deadline)Header(User buyer,User seller,address nftContract,address paymentToken)IBulk(uint256[] amounts,uint256[] tokenIds,uint256[] unitPrices,string[] tokenURIs)User(address addr,uint8 v,uint256 dealdine,bytes32 r,bytes32 s)User(address addr,uint8 v,uint256 deadline,bytes32 r,bytes32 s)"
        );

    function hash(Receipt memory receipt_) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    RECEIPT_TYPE_HASH,
                    __hashHeader(receipt_.header),
                    //__hashPayment(receipt_.payment),
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
                    __hashHeader(receipt_.header)
                    //__hashPayment(receipt_.payment),
                    //__hashBulk(receipt_.bulk)
                )
            );
    }

    function verifyReceipt(
        IGovernance admin_,
        address paymentToken_,
        uint256 total_,
        uint256 deadline_,
        bytes32 hashedReceipt_,
        bytes calldata signature_
    ) internal view {
        _verifyIntegrity(admin_, paymentToken_, total_, deadline_);
        if (
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(hashedReceipt_),
                signature_
            ) != admin_.verifier()
        ) {
            revert RU__InvalidSignature();
        }
    }

    function _verifyIntegrity(
        IGovernance admin_,
        address paymentToken_,
        uint256 total_,
        uint256 deadline_
    ) private view {
        if (block.timestamp > deadline_) {
            revert RU__Expired();
        }
        if (total_ != msg.value) {
            revert RU__InsufficientPayment();
        }
        if (!admin_.acceptedPayments(paymentToken_)) {
            revert RU__PaymentUnsuported();
        }
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
                    //header_.nonce,
                    //header_.deadline,
                    //header_.paymentToken,
                    header_.buyer,
                    header_.seller
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
                    //item_.nftContract,
                    keccak256(bytes(item_.tokenURI))
                )
            );
    }

    function __hashBulk(Bulk memory bulk_) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    BULK_TYPE_HASH,
                    //bulk_.nftContract,
                    bulk_.amounts,
                    bulk_.tokenIds
                    //bulk_.unitPrices
                )
            );
    }
}
