// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "./Interfaces/ICollectible.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error invalidAddress();

contract NFTFactory is Initializable, Ownable {
    using Clones for address;
    using Counters for Counters.Counter;
    //State Variables
    // address public s_implement; //the address of the base nft contract
    Counters.Counter public s_contractId;
    mapping(uint256 => address) public s_idToContractAddress;
    struct nftData {
        string uri;
        string name;
        string symbol;
    }

    //modifier
    modifier nonZeroAddress(address _addr) {
        if (_addr == address(0)) {
            revert invalidAddress();
        }
        _;
    }

    //methods
    constructor() Ownable() {}

    function deployNftContract(
        address _implement,
        string calldata _uri,
        string calldata _name,
        string calldata _symbol
    ) external returns (address deployedAddress) {
        nftData memory data = nftData({
            uri: _uri,
            name: _name,
            symbol: _symbol
        });
        deployedAddress = _deployNftContract(_implement, _msgSender(), data);
    }

    function _deployNftContract(
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
        s_idToContractAddress[s_contractId.current()] = deployedAddress;
        s_contractId.increment();
    }
    //pure, view method
}
