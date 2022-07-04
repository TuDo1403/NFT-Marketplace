// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./interfaces/IRoyaltyManager.sol";
import "./interfaces/IRoyaltyFeeRegisty.sol";

contract RoyaltyFeeManager is IRotaltyManager {
    IRoyaltyFeeRegister public immutable royaltyFeeRegistry;

    constructor(address _royaltyFeeRegisterAddress) {
        royaltyFeeRegistry = IRoyaltyFeeRegister(_royaltyFeeRegisterAddress);
    }

    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 amount
    ) external view override returns (address, uint256) {
        (address receiver, uint256 royaltyAmount) = royaltyFeeRegistry
            .royaltyInfo(collection, amount);

        return (receiver, royaltyAmount);
    }
}
