// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "./base/MarketplaceIntegratable.sol";
import "./base/INFTBase.sol";
import "./interfaces/INFT.sol";

import "./interfaces/INFTFactory.sol";
import "./interfaces/IGovernance.sol";

contract NFTFactory is
    INFTFactory,
    ContextUpgradeable,
    MarketplaceIntegratable
{
    using ClonesUpgradeable for address;

    //keccak256("NFTFactory_v1")
    bytes32 public constant VERSION =
        0xc42665b4953fdd2cb30dcf1befa0156911485f4e84e3f90b1360ddfb4fa2f766;

    mapping(uint256 => address) public deployedContracts;

    // constructor(address admin_) initializer {
    //     _initialize(admin_);
    // }

    function initialize(address admin_) external initializer {
        _initialize(admin_);
    }

    function deployCollectible(
        address implement_,
        string calldata name_,
        string calldata symbol_,
        string calldata baseURI_
    ) external override returns (address clone) {
        address owner = _msgSender();
        bytes32 salt = keccak256(
            abi.encodePacked(VERSION, name_, symbol_, baseURI_)
        );

        clone = implement_.cloneDeterministic(salt);
        (bool ok, ) = clone.call(
            abi.encodePacked(
                bytes4(0x3f2f5ee2), // initialize(address,address,string,string,string)
                abi.encode(address(admin), owner, name_, symbol_, baseURI_)
            )
        );
        if (!ok) {
            revert Factory__ExecutionFailed();
        }

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

    function _notMaliciousAddress(address addr_) private view {
        assert(addr_ != address(this));
    }
}
