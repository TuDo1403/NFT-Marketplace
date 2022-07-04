// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

import "./interfaces/ICollectible.sol";
import "node_modules/@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract Collectible is 
    ICollectible,
    Initializable
{
    // State variables
    address private factory;

    // Events

    // Functions
    function initialize(
        address _admin,
        string calldata _uri,
        string calldata _name,
        string calldata _symbol
    ) external virtual;
}