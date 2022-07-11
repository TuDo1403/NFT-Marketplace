// SPDX-License-Identifier: Unlisened
pragma solidity >=0.8.13;

import "./ICollectible.sol";

interface ICollectible1155 is ICollectible {
    error ERC1155__FrozenBase();
    error ERC1155__FrozenToken();
    error ERC1155__LengthMismatch();

    event PermanentURI(uint256 indexed tokenId_, string tokenURI_);

    function freezeBase() external;

    function freezeToken(uint256 tokenId_) external;

    function mintBatch(
        uint256[] calldata tokenIds_,
        uint256[] calldata amounts_
    ) external;

    function mintBatch(
        uint256[] calldata amounts_,
        string[] calldata tokenURIs_,
        TokenIdGenerator.Token[] calldata tokens_
    ) external;

    function lazyMintBatch(
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
