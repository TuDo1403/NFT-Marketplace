// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./ICollectible.sol";

interface ICollectible1155 is ICollectible {
    function mint(address to, uint256 tokenId, uint256 amount, bytes memory data) external;
    function mintBatch(address to, uint256[] memory tokenIds, uint256[] memory amounts, bytes memory data) external;
    function transferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory _data) external;
}