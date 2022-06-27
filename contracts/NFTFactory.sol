// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "./interfaces/INFTFactory.sol";
import "./interfaces/ICollectible.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract NFTFactory is INFTFactory, OwnableUpgradeable {
    using ClonesUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant VERSION = keccak256("Factory1155_v1");

    CountersUpgradeable.Counter public contractCounter;

    mapping(uint256 => address) public deployedContracts;

    modifier validAddress(address address_) {
        require(address_ != address(0), "Factory1155: invalid address");
        _;
    }

    function initialize() external initializer {
        __Ownable_init();
    }

    function deployCollectible(
        address implement_,
        string calldata uri_,
        string calldata name_,
        string calldata symbol_
    )
        external
        override
        validAddress(implement_)
        returns (address deployedAddress)
    {
        Settings memory settings = Settings({
            uri: uri_,
            name: name_,
            symbol: symbol_
        });
        deployedAddress = _deployCollectible(
            _msgSender(),
            implement_,
            settings
        );
    }

    function _deployCollectible(
        address deployer_,
        address implement_,
        Settings memory settings_
    ) internal returns (address deployedAddress) {
        bytes32 salt = keccak256(
            abi.encodePacked(
                settings_.name,
                settings_.symbol,
                settings_.uri,
                VERSION
            )
        );
        deployedAddress = implement_.cloneDeterministic(salt);
        ICollectible instance = ICollectible(deployedAddress);
        instance.initialize({
            admin_: deployer_,
            name_: settings_.name,
            symbol_: settings_.symbol,
            uri_: settings_.uri
        });
        deployedContracts[contractCounter.current()] = deployedAddress;
        contractCounter.increment();
        emit TokenDeployed({
            deployedAddress: deployedAddress,
            deployer: deployer_,
            standard: instance.getType(),
            uri: settings_.uri,
            name: settings_.name,
            symbol: settings_.symbol,
            createdTime: block.timestamp
        });
    }

    function deployMultipleCollectibles(
        address[] calldata deployers_,
        address[] calldata implements_,
        Settings[] calldata settings_
    ) external override returns (address[] memory deployedAddresses) {
        require(
            deployers_.length == implements_.length &&
                implements_.length == settings_.length,
            "Factory: invalid arguments"
        );

        uint256 numCalls = implements_.length;

        for (uint256 i; i < numCalls; ) {
            deployedAddresses[i] = _deployCollectible(
                deployers_[i],
                implements_[i],
                settings_[i]
            );
            unchecked {
                ++i;
            }
        }
    }
}
