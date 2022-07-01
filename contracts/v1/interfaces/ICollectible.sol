// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

interface ICollectible {
    event TokenMinted(
        uint256 id,
        address owner,
        string tokenURI,
        uint256 createdTime
    );

    function initialize(
        address admin_,
        string calldata uri_,
        string calldata name_,
        string calldata symbol_
    ) external;

    /**
    * Contract owner duoc quyen mint nft
     */
    function setTokenUri(uint256 tokenId, string memory uri) external;

    function freezeTokenData(uint256 id) external;

    function getType() external pure returns (uint96);

    function getCreator(uint256 tokenId) external view returns (address);
}
