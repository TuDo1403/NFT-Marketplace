// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

interface INFT {
    function mint(
        address to_,
        uint256 tokenId_,
        uint256 amount_,
        string memory tokenURI_
    ) external;
}
