// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "./interfaces/INFTFactory.sol";
import "./interfaces/ICollectible.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract NFTFactory is INFTFactory {
    // State variables
    uint256 public contractCounter;
    mapping(uint256 => address) public deployedContracts;

    mapping(address => address) public nftContractOwner;

    constructor() {
        contractCounter = 0;
    }

    // Functional
    function deployCollectible(
        address implement_,
        string calldata uri_,
        string calldata name_,
        string calldata symbol_
    ) external override returns (address deployedAddress) {
        Settings memory settings = Settings({
            uri: uri_,
            name: name_,
            symbol: symbol_
        });
        deployedAddress = _deployCollectible(msg.sender, implement_, settings);
        nftContractOwner[deployedAddress] = msg.sender;
    }

    function _deployCollectible(
        address deployer_,
        address implement_,
        Settings memory settings_
    ) internal returns (address deployedAddress) {
        bytes32 salt = keccak256(
            abi.encodePacked(settings_.name, settings_.symbol, settings_.uri)
        );
        deployedAddress = Clones.cloneDeterministic(implement_, salt);
        ICollectible instance = ICollectible(deployedAddress);
        instance.initialize({
            admin_: deployer_,
            name_: settings_.name,
            symbol_: settings_.symbol,
            uri_: settings_.uri
        });

        deployedContracts[contractCounter] = deployedAddress;
        contractCounter += 1;
        
        emit TokenDeployed({
            deployedAddress: deployedAddress,
            deployer: deployer_,
            uri: settings_.uri,
            name: settings_.name,
            symbol: settings_.symbol,
            createdTime: block.timestamp
        });
    }

    function getContractOwner(address nftContract) external view override returns (address) {
        address owner = nftContractOwner[nftContract];
        return owner;
    }

    // function deployMultipleCollectibles(
    //     address[] calldata deployers_,
    //     address[] calldata implements_,
    //     Settings[] calldata settings_
    // ) external override returns (address[] memory deployedAddresses) {
    //     require(
    //         deployers_.length == implements_.length &&
    //             implements_.length == settings_.length,
    //         "Factory: invalid arguments"
    //     );

    //     uint256 numCalls = implements_.length;

    //     for (uint256 i; i < numCalls; ) {
    //         deployedAddresses[i] = _deployCollectible(
    //             deployers_[i],
    //             implements_[i],
    //             settings_[i]
    //         );
    //         unchecked {
    //             ++i;
    //         }
    //     }
    // }
}
