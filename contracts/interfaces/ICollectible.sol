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

    function getVersion() external view returns (bytes32);

    function getType() external view returns (uint96);
}
