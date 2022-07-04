//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IRoyaltyFeeRegister {
    function updateRoyaltyInfo(
        address nftAddress,
        address setter,
        address receiver,
        uint256 feePercent
    ) external;

    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external;

    function royaltyInfo(address collection, uint256 amount)
        external
        view
        returns (address, uint256);

    function royaltyFeeInfoCollection(address collection)
        external
        view
        returns (
            address,
            address,
            uint256
        );
}
