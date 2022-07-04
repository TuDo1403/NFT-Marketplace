//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

interface IERC1155Collectible {
    event Token1155Minted(
        uint256 id,
        string tokenUri,
        uint256 createdTime,
        address creator
    );
}
