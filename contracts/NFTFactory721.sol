// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "./Collectible721.sol";
import "./base/MarketplaceIntegratable.sol";

import "./base/INFTBase.sol";
import "./interfaces/INFTFactory.sol";
import "./interfaces/IGovernance.sol";

contract NFTFactory721 is
    INFTFactory,
    ContextUpgradeable,
    MarketplaceIntegratable
{
    //keccak256("NFTFactory721_v1")
    bytes32 public constant VERSION =
        0x77d91f90058d075e52bc2e5ba935f4809fe46b3095987ff1341f05b47a4431c5;

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
            type(Collectible721).creationCode,
            abi.encode(admin, owner, name_, symbol_, baseURI_)
        );
        clone = Create2Upgradeable.deploy(0, salt, bytecode);
        deployedContracts[uint256(salt)] = clone;

        emit TokenDeployed(
            name_,
            symbol_,
            baseURI_,
            NFTBase(clone).TYPE(),
            owner,
            clone
        );
    }
}
