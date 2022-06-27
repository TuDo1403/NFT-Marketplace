// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

import "./interfaces/IMarketplace.sol";
import "node_modules/@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/// @custom:security-contact tudm@inspirelab.io
contract Marketplace is
    IMarketplace,
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant VERSION = keccak256("Marketplacev1");

    bytes32 public constant ADMIN = keccak256("ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    function initialize() external initializer {
        __Pausable_init();
        __AccessControl_init();
    }

    function listItem(
        address nftContract,
        uint256 itemId,
        uint256 price
    ) external override {}

    function unListItem(uint256 itemId) external override {}

    function buyNft(address nftContract, uint256 itemId)
        external
        payable
        override
    {
        ICollectible(nftContract).
    }

    function changeItemPrice(uint256 itemId, uint256 newPrice)
        external
        override
    {}
}
