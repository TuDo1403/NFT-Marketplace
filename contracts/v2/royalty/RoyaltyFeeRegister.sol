// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Ownable} from "node_modules/@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IRoyaltyFeeRegisty.sol";

contract RoyaltyFeeRegister is IRoyaltyFeeRegister, Ownable {
    struct RoyaltyFee {
        address setter;
        address recipient;
        uint256 feePercent; /**1 ~ 0.01% => 10000 ~ 100% */
    }
    uint256 public royaltyFeeLimit;

    mapping(address => RoyaltyFee) _royaltyFeeInfoCollection;

    constructor(uint256 _royaltyFeeLimit) {
        require(_royaltyFeeLimit <= 9500, "RoyaltyFeeRegister: Royalty fee limit too high!");
        royaltyFeeLimit = _royaltyFeeLimit;
    }

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

    function royaltyInfo(address collection, uint256 amount)
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
