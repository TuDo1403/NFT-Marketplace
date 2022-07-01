// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

import "./ICollectible.sol";

interface ICollectible721 is ICollectible {
    // Events
    event ERC721Created(
        string uri,
        string name,
        string symbol,
        uint256 createdTime,
        address indexed owner,
        address indexed newAddress
    );

    // Functional
    function mint(address to, uint256 tokenId) external;

    function getType() external pure returns (uint96); 

    function getCreator(uint256 tokenId) external view returns (address);
}
