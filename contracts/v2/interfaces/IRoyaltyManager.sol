// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IRotaltyManager {
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 amount
    ) external view returns (address, uint256);
}
