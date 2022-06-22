// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

interface IFactory {
    struct Settings {
        string uri;
        string name;
        string symbol;
        string version;
    }

    event TokenDeployed(
        uint256 createdTime,
        string uri,
        string name,
        string symbol,
        string indexed version,
        address indexed owner,
        address indexed deployedAddress
    );

    function deployCollectible(address _implement, Settings calldata _settings)
        external
        returns (address deployedAddress);
}
