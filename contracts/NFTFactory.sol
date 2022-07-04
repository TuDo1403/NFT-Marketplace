// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "./Interfaces/ICollectible.sol";
import "./Interfaces/INFTFactory.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

error invalidAddress();

contract NFTFactory is INFTFactory, OwnableUpgradeable {
    using ClonesUpgradeable for address;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    //State Variables
    CountersUpgradeable.Counter public s_contractId;
    mapping(uint256 => address) public s_idToContractAddress;

    //modifier
    modifier nonZeroAddress(address _addr) {
        if (_addr == address(0)) {
            revert invalidAddress();
        }
        _;
    }

    //methods
    function initialize() external {
        __Ownable_init();
    }

    //deploy ERC721 contract
    function createNft(
        address _implement,
        string calldata _uri,
        string calldata _name,
        string calldata _symbol
    ) external override returns (address deployedAddress) {
        nftData memory data = nftData({
            uri: _uri,
            name: _name,
            symbol: _symbol
        });
        deployedAddress = _createNft(_implement, _msgSender(), data);
    }

    function _createNft(
        address _implement,
        address _nftCreator,
        nftData memory _data
    ) internal returns (address deployedAddress) {
        bytes32 salt = keccak256(
            abi.encodePacked(_data.uri, _data.name, _data.symbol)
        );
        deployedAddress = _implement.cloneDeterministic(salt);
        ICollectible newCollectible = ICollectible(deployedAddress);
        newCollectible.initialize(
            _nftCreator,
            _data.uri,
            _data.name,
            _data.symbol
        );
        emit nftCreated(
            deployedAddress,
            _nftCreator,
            _data.uri,
            _data.name,
            _data.symbol,
            block.timestamp
        );
        s_idToContractAddress[s_contractId.current()] = deployedAddress;
        s_contractId.increment();
    }

    // deploy ERC1155 contract
    //pure, view method
}
