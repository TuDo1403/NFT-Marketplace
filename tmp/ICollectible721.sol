// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

interface ICollectible721 {
    event ERC721Created(
        string uri,
        string name,
        string symbol,
        uint256 createdTime,
        address indexed owner,
        address indexed newAddress
    );
}
