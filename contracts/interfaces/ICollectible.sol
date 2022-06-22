// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

interface ICollectible {
    function initialize(
        address manager,
        string calldata name,
        string calldata symbol,
        string calldata uri
    ) external;

    function getVersion() external view returns (string memory);
}
