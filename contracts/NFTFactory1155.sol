// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";
import "./base/MarketplaceIntegratable.sol";
import "./Collectible1155.sol";

import "./base/INFTBase.sol";
import "./interfaces/INFTFactory.sol";
import "./interfaces/IGovernance.sol";

contract NFTFactory1155 is
    INFTFactory,
    MarketplaceIntegratable,
    ContextUpgradeable
{
    //keccak256("NFTFactory1155_v1")
    bytes32 public constant VERSION =
        0xf4d0561b5f6e1e5f8cb96e6d518884af129a597ed8278acfc07f4424835889db;

    mapping(uint256 => address) public deployedContracts;

    function initialize(address admin_) external initializer {
        _initialize(admin_);
    }

    function deployCollectible(
        string calldata name_,
        string calldata symbol_,
        string calldata baseURI_
    ) external override returns (address clone) {
        address owner = _msgSender();
        bytes32 salt = keccak256(
            abi.encodePacked(VERSION, name_, symbol_, baseURI_)
        );

        bytes memory bytecode = abi.encodePacked(
            type(Collectible1155).creationCode,
            abi.encode(address(admin), owner, name_, symbol_, baseURI_)
        );
        clone = Create2Upgradeable.deploy(0, salt, bytecode);
        deployedContracts[uint256(salt)] = clone;
        emit TokenDeployed(
            name_,
            symbol_,
            baseURI_,
            INFTBase(clone).TYPE(),
            owner,
            clone
        );
    }
}
