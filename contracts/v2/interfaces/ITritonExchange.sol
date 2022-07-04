// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {OrderTypes} from "../libraries/OrderTypes.sol";

/// @title Triton Exchange
/// @author datndt@inspirelab.io
/// @notice Contract for activity exchange, role: maker & taker, operation: ask & bid.
/// @dev Explain to a developer any extra details

interface ITritonExchange {
    // Events
    event ItemUnlisted (
        address nftAddress,
        uint256 tokenId,
        uint256 timestamp
    );

    event MatchAsk (
        address nftAddress,
        uint256 tokenId,
        address seller,
        address buyer,
        uint256 price,
        uint256 timestamp
    );

    event MatchBid (
        address nftAddress,
        uint256 tokenId,
        address seller,
        address buyer,
        uint256 price,
        uint256 timestamp
    );
    // Functions
    function matchAskWithTakerBidUsingETHAndWETH(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external payable;

    function matchBidWithTakerAsk(
        OrderTypes.TakerOrder calldata takerAsk,
        OrderTypes.MakerOrder calldata makerBid
    ) external payable;

    function matchAskWithTakerBid(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external payable;
}