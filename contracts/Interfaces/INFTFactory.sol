// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

interface INFTFactory {
    struct nftData {
        string uri;
        string name;
        string symbol;
    }

    event nftCreated(
        address indexed deployedAddress,
        address indexed creator,
        string uri,
        string name,
        string symbol,
        uint256 createdTime
    );

    function createNft(
        address _implement,
        string calldata _uri,
        string calldata _name,
        string calldata _symbol
    ) external returns (address deployedAddress);
}
