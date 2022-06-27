// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

import "./ICollectible.sol";

interface ICollectible1155 is ICollectible {
    event ERC1155Created(
        string uri,
        string name,
        string symbol,
        uint256 createdTime,
        address indexed owner,
        address indexed newAddress
    );

    event URI(string value, uint256 indexed id);

    event PermanentURI(uint256 indexed id, string uri);
}
