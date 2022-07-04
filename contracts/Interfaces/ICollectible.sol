//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

interface ICollectible {
    function initialize(
        address _nftCreator,
        string calldata _uri,
        string calldata _name,
        string calldata _symbol
    ) external;
}
