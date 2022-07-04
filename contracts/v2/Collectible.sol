// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

import "./interfaces/ICollectible.sol";
// import "node_modules/@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract Collectible is 
    ICollectible
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
    ) external virtual {}

    function getType() external virtual returns (uint96) {}

    function setTokenURI(uint256 token, bytes memory uri) external virtual {}

    function freezeTokenURI(uint256 tokenId) external virtual {}
}