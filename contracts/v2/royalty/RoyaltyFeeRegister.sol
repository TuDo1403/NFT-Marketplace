// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Ownable} from "node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IRoyaltyFeeRegisty.sol";

/// @title Royalty fee Register
/// @author Dat Nguyen (datndt@inspirelab.io)

contract RoyaltyFeeRegister is IRoyaltyFeeRegister, Ownable {
    struct RoyaltyFee {
        address setter;
        address recipient;
        uint256 feePercent; /**1 ~ 0.01% => 10000 ~ 100% */
    }
    uint256 public royaltyFeeLimit;

    mapping(address => RoyaltyFee) private _royaltyFeeInfoCollection;

    /**
     * @notice Constructor
     * @param _royaltyFeeLimit Register fee limit
     */
    constructor(uint256 _royaltyFeeLimit) {
        require(
            _royaltyFeeLimit <= 9500,
            "RoyaltyFeeRegister: Royalty fee limit too high!"
        );
        royaltyFeeLimit = _royaltyFeeLimit;
    }

    /**
     * @notice Update Royalty Info
     * @param nftAddress Address of NFT
     * @param setter Address of setter
     * @param receiver Address of royalty fee receiver
     * @param feePercent Percentage of royalty fee
     */
    function updateRoyaltyInfo(
        address nftAddress,
        address setter,
        address receiver,
        uint256 feePercent
    ) external override {
        require(
            feePercent <= royaltyFeeLimit,
            "RoyaltyFeeRegister: Fee is too high!"
        );

        _royaltyFeeInfoCollection[nftAddress] = RoyaltyFee({
            setter: setter,
            recipient: receiver,
            feePercent: feePercent
        });
    }

    /**
     * @notice Update Royalty fee
     * @param _royaltyFeeLimit New fee limit */
    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit)
        external
        override
        onlyOwner
    {
        require(
            _royaltyFeeLimit <= 9500,
            "RoyaltyFeeRegister: Fee limit is too high!"
        );
        royaltyFeeLimit = _royaltyFeeLimit;
    }

    /**
     * @notice Get royalty info
     * @param nftAddress Address of NFT
     * @param amount Amount of token
     * @return (address of receiver, amount in percentage)
     */
    function royaltyInfo(address nftAddress, uint256 amount)
        external
        view
        override
        returns (address, uint256)
    {
        return (
            _royaltyFeeInfoCollection[collection].receiver,
            (amount * _royaltyFeeInfoCollection[collection].fee) / 10000
        );
    }

    /**
     * @notice Get royalty fee info
     * @param nftAddress Address of NFT
     * @return (address of setter, receiver, fee percent)
     */
    function royaltyFeeInfoCollection(address nftAddress)
        external
        view
        override
        returns (
            address,
            address,
            uint256
        )
    {
        return (
            _royaltyFeeInfoCollection[nftAddress].setter,
            _royaltyFeeInfoCollection[nftAddress].recipient,
            _royaltyFeeInfoCollection[nftAddress].feePercent
        );
    }
}
