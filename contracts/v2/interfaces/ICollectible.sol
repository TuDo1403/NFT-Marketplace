// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface ICollectible {
    // Events
    event TokenMinted (
        address nftAddress,
        uint256 tokenId,
        uint256 amount, /**ERC1155 */
        address to,
        uint256 timestamp
    );

    function initialize(
        address _admin,
        string calldata _uri,
        string calldata _name,
        string calldata _symbol
    ) external;

    function getType() external returns (uint96);

    function setTokenURI(uint256 token, bytes memory uri) external;

    function freezeTokenURI(uint256 tokenId) external;
}