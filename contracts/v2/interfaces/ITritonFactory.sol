// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface ITritonFactory {
    struct Settings {
        string uri;
        string name;
        string symbol;
    }

    event NftContractDeployed (
        address nftAddress,
        address owner,
        string name,
        string symbol,
        uint256 timestamp
    );

    function deployContract(
        address _deployer,
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) external returns (address deployedAddress);
}