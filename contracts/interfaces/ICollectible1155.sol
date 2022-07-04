// SPDX-License-Identifier: Unlisened
pragma solidity 0.8.15;

import "./ICollectible.sol";

interface ICollectible1155 is ICollectible {
    struct Bulk {
        uint256[] amounts;
        uint256[] tokenIds;
        uint256[] unitPrices;
        // string[] tokenURIs;
    }

    struct BulkPayment {
        uint256 total;
        uint256 subTotal;
        uint256 creatorPayout;
        uint256 servicePayout;
        address[] paymentTokens;
    }

    struct BulkReceipt {
        uint256 deadline;
        uint256 nonce;
        address buyer;
        address seller;
        // address[] creators;
        // address[] creatorPayoutAddrs;
        Bulk bulk;
        BulkPayment payment;
    }
    event PermanentURI(uint256 indexed id, string uri);

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
    ) external payable;

    function freezeToken(uint256 tokenId_) external;

    function mintBatch(
        uint256[] calldata tokenIds_,
        uint256[] calldata amounts_
    ) external;

    function mintBatch(
        uint256[] calldata types_,
        uint256[] calldata creatorFees_,
        uint256[] calldata indices_,
        uint256[] calldata supplies_,
        uint256[] calldata amounts_,
        string[] calldata tokenURIs_
    ) external;
}
