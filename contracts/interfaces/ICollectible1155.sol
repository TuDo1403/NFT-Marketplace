// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

import "./ICollectible.sol";

interface ICollectible1155 is ICollectible {
    error ERC1155__LengthMismatch();

    function initialize(
        address owner_,
        string calldata name_,
        string calldata symbol_,
        string calldata baseURI_
    ) external;

    function mint(uint256 tokenId_, uint256 amount_) external;

    function mint(
        address to_,
        uint256 tokenId_,
        uint256 amount_,
        string calldata tokenURI_
    ) external;

    function mintBatch(
        uint256[] calldata tokenIds_,
        uint256[] calldata amounts_
    ) external;

    function mintBatch(
        address to_,
        uint256[] calldata tokenIds_,
        uint256[] calldata amounts_,
        string[] calldata tokenURIs_
    ) external;

    function transferBatch(
        address from_,
        address to_,
        uint256[] memory amounts_,
        uint256[] memory tokenId_
    ) external;
}
