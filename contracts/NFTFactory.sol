// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "./Interfaces/INFTFactory.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract NFTFactory is OwnableUpgradeable, INFTFactory {
    // State Variables
    using ClonesUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    address public ERC1155Implementation;
    address public ERC721Implementation;
    CountersUpgradeable.Counter public contractId;
    mapping(uint256 => address) public idToContractAddress;

    // Modifiers
    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "Address is a zero address");
        _;
    }

    function initialize() external initializer {
        __Ownable_init();
    }

    //Deploy NFT contract
    function deployNFT(
        address _implement,
        string calldata _name,
        string calldata _symbol,
        string calldata _uri
    )
        external
        override
        nonZeroAddress(_implement)
        returns (address deployedAddress)
    {
        deployedAddress = _deployNFT(_implement, _name, _symbol, _uri);
    }

    function _deployNFT(
        address _implement,
        string calldata _name,
        string calldata _symbol,
        string calldata _uri
    ) internal returns (address deployedAddress) {
        bytes32 salt = keccak256(abi.encodePacked(_name, _symbol, _uri));
        deployedAddress = _implement.cloneDeterministic(salt);
        idToContractAddress[contractId.current()] = deployedAddress;
        contractId.increment();
    }
}
