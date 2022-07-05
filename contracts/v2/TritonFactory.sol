// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./interfaces/ITritonFactory.sol";
import "./interfaces/ICollectible.sol";

import "node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "node_modules/@openzeppelin/contracts/proxy/Clones.sol";
import "node_modules/@openzeppelin/contracts/utils/Context.sol";

/// @title Triton Factory
/// @author Dat Nguyen (datndt@inspirelab.io)

contract TritonFactory is ITritonFactory, Context {
    mapping(uint256 => address) nftContract;
    using Counters for Counters.Counter;
    Counters.Counter private nftCounter;

    /**
     * @notice Deploy nft contract based on implementation contract
     * @param implementation_ Base NFT Contract
     * @param name_ Name of NFT Contract
     * @param symbol_ Symbol of NFT Contract
     * @param uri_ URI of NFT Contract
     */
    function deployContract(
        address implementation_,
        string memory name_,
        string memory symbol_,
        string memory uri_
    ) external override returns (address deployedAddress) {
        Settings memory settings = Settings({
            name: name_,
            symbol: symbol_,
            uri: uri_
        });

        deployedAddress = _deployContract(
            _msgSender(),
            implementation_,
            settings
        );

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

    /**
     * @notice Deploy nft contract based on implementation contract
     * @param from_ Address of nft contract owner
     * @param implementation_ Base NFT Contract
     * @param settings_ Symbol of NFT Contract
     * @return deployedAddress Address of created NFT Contract
     */
    function _deployContract(
        address from_,
        address implementation_,
        Settings memory settings_
    ) private returns (address deployedAddress) {
        // Create salt
        bytes32 salt = keccak256(
            abi.encodePacked(settings_.name, settings_.symbol, settings_.uri)
        );

        // Deployed address
        deployedAddress = Clones.cloneDeterministic(implementation_, salt);

        // Create instance of collectible
        ICollectible instance = ICollectible(deployedAddress);
        instance.initialize({
            _admin: from_,
            _name: settings_.name,
            _symbol: settings_.symbol,
            _uri: settings_.uri
        });
    }
}
