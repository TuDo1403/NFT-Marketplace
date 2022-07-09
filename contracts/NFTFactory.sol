// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

import "./interfaces/ICollectible.sol";
import "./interfaces/INFTFactory.sol";
import "./interfaces/IGovernance.sol";

contract NFTFactory is INFTFactory {
    using ClonesUpgradeable for address;

    address public governance;
    address public marketplace;

    bytes32 public constant VERSION = keccak256("NFTFactoryv1");

    mapping(uint256 => address) public deployedContracts;

    modifier onlyOwner() {
        if (msg.sender != IGovernance(governance).manager()) {
            revert Unauthorized();
        }
        _;
    }

    modifier validAddress(address addr_) {
        if (addr_ == address(0)) {
            revert InvalidAddress();
        }
        _;
    }

    //796772
    constructor(address governance_, address marketplace_) {
        governance = governance_;
        marketplace = marketplace_;
    }

    function setMarketplace(address marketplace_)
        external
        validAddress(marketplace_)
        onlyOwner
    {
        marketplace = marketplace_;
    }

    function setGovernance(address governance_)
        external
        validAddress(governance_)
        onlyOwner
    {
        governance = governance_;
    }

    function deployCollectible(
        address implement_,
        string calldata name_,
        string calldata symbol_,
        string calldata baseURI_
    ) external returns (address clone) {
        address owner = msg.sender;
        bytes32 salt = keccak256(
            abi.encodePacked(VERSION, name_, symbol_, baseURI_)
        );

        clone = implement_.cloneDeterministic(salt);
        deployedContracts[uint256(salt)] = clone;

        ICollectible instance = ICollectible(clone);
        instance.initialize(marketplace, owner, name_, symbol_, baseURI_);
        emit TokenDeployed(
            name_,
            symbol_,
            baseURI_,
            string(abi.encodePacked(instance.TYPE())),
            owner,
            clone
        );
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
                revert ExecutionFailed();
            }
            results[i] = result;
            unchecked {
                ++i;
            }
        }
    }
}
