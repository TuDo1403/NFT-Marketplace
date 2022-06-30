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

    // function mint(address to, uint256 tokenId, uint256 amount, bytes memory data) external;

    // function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data ) external;
}
