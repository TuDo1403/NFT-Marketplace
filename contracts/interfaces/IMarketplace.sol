// SPDX-License-Identifier: Unlisened
pragma solidity >=0.8.13;

import "./IPausable.sol";
import "../libraries/ReceiptUtil.sol";

interface IMarketplace is IPausable {
    error Expired();
    error InvalidInput();
    error Unauthorized();
    error LengthMismatch();
    error ExecutionFailed();
    error PaymentFailed();
    error PaymentUnsuported();
    error InvalidSignature();

    event ItemRedeemed(
        address indexed nftContract,
        address indexed buyer,
        uint256 indexed tokenId,
        address paymentToken,
        uint256 unitPrice,
        uint256 total
    );

    event BulkRedeemed(
        address indexed nftContract,
        address indexed buyer,
        uint256[] tokenIds,
        address paymentToken,
        uint256[] unitPrices,
        uint256 total
    );

    function multiDelegatecall(bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results);

    function redeem(
        address seller_,
        address paymentToken_,
        address creatorPayoutAddr_,
        uint256 deadline_,
        ReceiptUtil.Item calldata item_,
        string calldata tokenURI_,
        bytes calldata signature_
    ) external payable;

    function redeemBulk(
        uint256 deadline_,
        address seller_,
        address paymentToken_,
        address creatorPayoutAddr_,
        bytes calldata signature_,
        ReceiptUtil.Bulk calldata bulk_,
        string[] calldata tokenURIs_
    ) external payable;

    function setAdmin(address admin_) external;
}
