// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

import "./interfaces/ICollectible1155.sol";
import "./interfaces/INFTFactory.sol";
import "./interfaces/IGovernance.sol";

contract NFTFactory1155 is INFTFactory {
    using ClonesUpgradeable for address;

    address public governance;

    bytes32 public constant VERSION = keccak256("NFTFactory1155v1");

    mapping(uint256 => address) public deployedContracts;

    modifier onlyOwner() {
        if (msg.sender != IGovernance(governance).manager()) {
            revert Factory__Unauthorized();
        }
        _;
    }

    modifier validAddress(address addr_) {
        if (addr_ == address(0)) {
            revert Factory__InvalidAddress();
        }
        _;
    }

    //796772
    constructor(address governance_) validAddress(governance_) {
        governance = governance_;
    }

    function setGovernance(address governance_)
        external
        validAddress(governance_)
        onlyOwner
    {
        governance = governance_;
    }

    function deployCollectible1155(
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

        ICollectible1155 instance = ICollectible1155(clone);
        instance.initialize(owner, name_, symbol_, baseURI_);
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
        returns (bytes[] memory)
    {
        bytes[] memory results = new bytes[](data.length);
        for (uint256 i; i < data.length; ) {
            (bool ok, bytes memory result) = address(this).delegatecall(
                data[i]
            );
            if (!ok) {
                revert Factory__ExecutionFailed();
            }
            results[i] = result;
            unchecked {
                ++i;
            }
        }
        return results;
    }
}
