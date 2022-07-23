// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
//import "../external/contracts/utils/cryptography/ECDSA.sol";

import "../interfaces/IGovernance.sol";
import "./TokenIdGenerator.sol";
import "hardhat/console.sol";

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

    ///@dev value is equal to keccak256("User(address addr,uint8 v,uint256 deadline,bytes32 r,bytes32 s)")
    bytes32 private constant USER_TYPE_HASH =
        0x608b3f6b5846eeb165cc065962f4f67e8bc514fff7e7931191b7345873427549;

    ///@dev Value is equal to keccak256("Header(User buyer,User seller,address nftContract,address paymentToken)User(address addr,uint8 v,uint256 deadline,bytes32 r,bytes32 s)")
    bytes32 private constant HEADER_TYPE_HASH =
        0x6e454651a1dcd0f7216467b9d24177e22fb1c1a0fe79e0191caaf33b1b2d22ad;

    ///@dev Value is equal to keccak256("Item(uint256 amount,uint256 tokenId,uint256 unitPrice,string tokenURI)")
    bytes32 private constant ITEM_TYPE_HASH =
        0xbb947806069955a6c604055c1ed4c84bcab0a154ff5365158c52c141bb25852d;

    ///@dev Value is equal to keccak256("Bulk(uint256[] amounts,uint256[] tokenIds,uint256[] unitPrices,string[] tokenURIs)")
    bytes32 private constant BULK_TYPE_HASH =
        0x97a8084b05295a1a0b029b05bda73d5917d940d10e22aa7b9d94f19a379e7bf8;

    ///@dev value is equal to keccak256("Receipt(Header header,Item item,uint256 nonce,uint256 deadline)Header(User buyer,User seller,address nftContract,address paymentToken)User(address addr,uint8 v,uint256 deadline,bytes32 r,bytes32 s)Item(uint256 amount,uint256 tokenId,uint256 unitPrice,string tokenURI)")
    bytes32 private constant RECEIPT_TYPE_HASH =
        0xe12da5126137442eee6aa47b09af013f90ebdd5c92e75d9a3badef17abb89d34;

    ///@dev value is equal to keccak256("BulkReceipt(Header header,Bulk bulk,uint256 nonce,uint256 deadline)Bulk(uint256[] amounts,uint256[] tokenIds,uint256[] unitPrices,string[] tokenURIs)Header(User buyer,User seller,address nftContract,address paymentToken)User(address addr,uint8 v,uint256 deadline,bytes32 r,bytes32 s)")
    bytes32 private constant BULK_RECEIPT_TYPE_HASH =
        0xcfcb4da075a0d56b79ee3b56f70cb4cdcda5e155a086ae0a84cda374e2105f71;

    function hash(Receipt memory receipt_) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    RECEIPT_TYPE_HASH,
                    __hashHeader(receipt_.header),
                    __hashItem(receipt_.item),
                    receipt_.nonce,
                    receipt_.deadline
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
                    BULK_RECEIPT_TYPE_HASH,
                    __hashHeader(receipt_.header),
                    __hashBulk(receipt_.bulk),
                    receipt_.nonce,
                    receipt_.deadline
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
        if (total_ != msg.value) {
            revert RU__InsufficientPayment();
        }
        if (!admin_.acceptedPayments(paymentToken_)) {
            revert RU__PaymentUnsuported();
        }
        if (block.timestamp > deadline_) {
            revert RU__Expired();
        }
    }

    function __hashUser(User memory user_) private pure returns (bytes32) {
        return
            keccak256(
                (
                    abi.encode(
                        USER_TYPE_HASH,
                        user_.addr,
                        user_.v,
                        user_.deadline,
                        user_.r,
                        user_.s
                    )
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
                    __hashUser(header_.buyer),
                    __hashUser(header_.seller),
                    header_.nftContract,
                    header_.paymentToken
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
                    keccak256(bytes(item_.tokenURI))
                )
            );
    }

    function __hashBulk(Bulk memory bulk_) private pure returns (bytes32) {
        bytes32[] memory _tokenURIs = new bytes32[](bulk_.tokenURIs.length);
        for (uint256 i; i < _tokenURIs.length; ) {
            _tokenURIs[i] = keccak256(bytes(bulk_.tokenURIs[i]));
            unchecked {
                ++i;
            }
        }
        return
            keccak256(
                abi.encode(
                    BULK_TYPE_HASH,
                    bulk_.amounts,
                    bulk_.tokenIds,
                    bulk_.unitPrices,
                    keccak256(abi.encodePacked(_tokenURIs))
                )
            );
    }
}
