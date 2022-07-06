// SPDX-License-Identifier: Unlisened
pragma solidity >=0.8.13;

import "./ICollectible.sol";


interface ICollectible1155 is ICollectible {
    error LengthMismatch();

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
