// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./interfaces/INFTFactory.sol";
import "./interfaces/ICollectible.sol";

contract NFTFactory is INFTFactory, OwnableUpgradeable {
    using ClonesUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant VERSION = keccak256("NFTFactoryv1");

    CountersUpgradeable.Counter public contractCounter;

    mapping(uint256 => address) public deployedContracts;

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
        returns (
            //validAddress(implement_)
            address deployedAddr
        )
    {
        if (implement_ == address(0)) {
            revert InvalidAddress();
        }
        Settings memory settings = Settings(uri_, name_, symbol_);
        deployedAddr = __deployCollectible(_msgSender(), implement_, settings);
    }

    function __deployCollectible(
        address deployer_,
        address implement_,
        Settings memory settings_
    ) private returns (address deployedAddr) {
        bytes32 salt = keccak256(
            abi.encodePacked(
                VERSION,
                settings_.uri,
                settings_.name,
                settings_.symbol
            )
        );
        deployedAddr = implement_.cloneDeterministic(salt);
        ICollectible instance = ICollectible(deployedAddr);
        instance.initialize({
            owner_: deployer_,
            name_: settings_.name,
            symbol_: settings_.symbol,
            baseURI_: settings_.uri
        });

        deployedContracts[contractCounter.current()] = deployedAddr;
        contractCounter.increment();
        emit TokenDeployed({
            deployedAddress: deployedAddr,
            deployer: deployer_,
            standard: string(abi.encodePacked(instance.TYPE())),
            uri: settings_.uri,
            name: settings_.name,
            symbol: settings_.symbol
        });
    }

    function multiDelegatecall(bytes[] calldata data)
        external
        onlyOwner
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);
        for (uint256 i; i < data.length; ) {
            (bool ok, bytes memory result) = address(this).delegatecall(
                data[i]
            );
            if (!ok) {
                revert DelegatecallFailed();
            }
            results[i] = result;
            unchecked {
                ++i;
            }
        }
    }
}
