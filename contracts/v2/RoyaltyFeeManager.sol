// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./interfaces/IRoyaltyManager.sol";
import "./interfaces/IRoyaltyFeeRegisty.sol";

/**
 * @title Manage royalty fee
 * @author Dat Nguyen (datndt@inspirelab.io)
 */

contract RoyaltyFeeManager is IRotaltyManager {
    IRoyaltyFeeRegister public immutable royaltyFeeRegistry;

    /**
    * @notice Constructor
    * @param royaltyFeeRegisterAddress Address of royalty fee registry
     */
    constructor(address royaltyFeeRegisterAddress) {
        royaltyFeeRegistry = IRoyaltyFeeRegister(royaltyFeeRegisterAddress);
    }

    /**
    * @notice Get royalty fee & recipient address
    * @param nftAddress Address of NFT
    * @param amount Amount of NFT
    * @return (address of reciever, amount of royalty)*/
    function calculateRoyaltyFeeAndGetRecipient(
        address nftAddress,
        uint256 amount
    ) external view override returns (address, uint256) {
        (address receiver, uint256 royaltyAmount) = royaltyFeeRegistry
            .royaltyInfo(nftAddress, amount);

        return (receiver, royaltyAmount);
    }
}
