// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;
import "./INFT.sol";

interface ISemiNFT is INFT {
    function mint(uint256 tokenId_, uint256 amount_) external;

    function mint(
        address to_,
        uint256 tokenId_,
        uint256 amount_,
        string memory tokenURI_
    ) external;

    function mintBatch(
        uint256[] calldata tokenIds_,
        uint256[] calldata amounts_
    ) external;

    function mintBatch(
        address to_,
        uint256[] memory tokenIds_,
        uint256[] memory amounts_,
        string[] memory tokenURIs_
    ) external;
}
