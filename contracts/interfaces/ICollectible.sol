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
    function mint(address to, uint256 tokenId, uint256 amount) external;

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

    function getType() external pure returns (uint96);

    function getCreator(uint256 tokenId) external view returns (address);
}
