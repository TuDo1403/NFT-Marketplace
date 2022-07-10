// SPDX-License-Identifier: Unlisened
pragma solidity >=0.8.13;
import "./IPausable.sol";
import "./IGovernance.sol";

import "../libraries/ReceiptUtil.sol";

interface IMarketplace is IPausable {
    error MP__Expired();
    error MP__InvalidInput();
    error MP__Unauthorized();
    error MP__PaymentFailed();
    error MP__LengthMismatch();
    error MP__ExecutionFailed();
    error MP__InvalidSignature();
    error MP__PaymentUnsuported();
    error MP__InsufficientPayment();

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
        uint256 deadline_,
        ReceiptUtil.Receipt calldata receipt_,
        bytes calldata signature_
    ) external payable;

    function redeemBulk(
        uint256 deadline_,
        ReceiptUtil.BulkReceipt calldata receipt_,
        bytes calldata signature_
    ) external payable;
}
