// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./interfaces/ITritonFactory.sol";

import "./interfaces/ICollectible.sol";

import "node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "node_modules/@openzeppelin/contracts/proxy/Clones.sol";
import "node_modules/@openzeppelin/contracts/utils/Context.sol";

contract TritonFactory is ITritonFactory, Context {
    // State variables
    mapping(uint256 => address) nftContract;

    using Counters for Counters.Counter;
    Counters.Counter private nftCounter;

    // Modifier

    constructor() {

    }

    // Functions
    function deployContract(
        address _implementation,
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) external override returns (address deployedAddress) {
        Settings memory settings = Settings({
            name: _name,
            symbol: _symbol,
            uri: _uri
        });

        deployedAddress = _deployContract(_msgSender(), _implementation, settings);

        nftContract[nftCounter.current()] = deployedAddress;
        nftCounter.increment();

        emit NftContractDeployed(
            deployedAddress,
            _msgSender(),
            settings.name,
            settings.symbol,
            block.timestamp
        );
    }

    function _deployContract(
        address _from, 
        address _implementation, 
        Settings memory _settings
    ) private returns (address deployedAddress) {
        // Create salt
        bytes32 salt = keccak256(
            abi.encodePacked(_settings.name, _settings.symbol, _settings.uri)
        );

        // Deployed address
        deployedAddress = Clones.cloneDeterministic(_implementation, salt);

        // Create instance of collectible
        ICollectible instance = ICollectible(deployedAddress);
        instance.initialize({
            _admin: _from,
            _name: _settings.name,
            _symbol: _settings.symbol,
            _uri: _settings.uri
        });
    }
}