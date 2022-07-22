// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

interface ITokenFreezable {
    error TokenFreezable__FrozenBase();
    error TokenFreezable__FrozenToken();
    error TokenFreezable__Unauthorized();

    event PermanentURI(uint256 indexed tokenId_, string tokenURI_);

    function setBaseURI(string calldata baseURI_) external;

    function freezeBaseURI() external;

    function freezeToken(uint256 tokenId_) external;
}
