// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

interface INFT {
    error NFT__StringTooLong();

    function initialize(
        address admin_,
        address owner_,
        string calldata name_,
        string calldata symbol_,
        string calldata baseURI_
    ) external;

    function mint(
        address to_,
        uint256 tokenId_,
        uint256 amount_,
        string memory tokenURI_
    ) external;
}
