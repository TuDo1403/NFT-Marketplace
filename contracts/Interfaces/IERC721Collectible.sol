// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

interface IERC721Collectibe {
    event Token721Minted(
        uint256 id,
        string tokenUri,
        uint256 createdTime,
        address creator
    );

    event URI(string value, uint256 indexed id);
}
