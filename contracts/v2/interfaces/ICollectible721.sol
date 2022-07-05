// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./ICollectible.sol";

interface ICollectible721 is ICollectible {
    function mint(address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
}