// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

interface INFTFactory {
    event NFTDeploy(
        address indexed deployedAddress,
        address indexed owner,
        string uri,
        string name,
        string symbol
    );

    function deployNFT(
        address implement,
        string calldata name,
        string calldata symbol,
        string calldata uri
    ) external returns (address deployedAddress);
}
