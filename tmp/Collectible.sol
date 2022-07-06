// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

//0x5B5852a788797882C41295Cba4fAFeC9A3e1d04C factory
//0x693eDcEc35d9ce627979400C9Ed452a734d104B1 base
//0xaA58A19Ad06486fb2A91e9097a9DdD7edaC48DeB clone

import "./interfaces/ICollectible.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

abstract contract Collectible is
    ICollectible,
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    uint96 private _type;
    address private _factory;
    bytes32 private _version;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    modifier onlyFactory(address address_) {
        require(_factory == address_, "Collectible: Only Factory");
        _;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function initialize(
        address admin_,
        string calldata name_,
        string calldata symbol_,
        string calldata uri_
    ) external override initializer {
        __AccessControl_init();
        __Pausable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(PAUSER_ROLE, admin_);
        _grantRole(MINTER_ROLE, admin_);
        _factory = _msgSender();
        _initialize(admin_, name_, symbol_, uri_);
    }

    function _initialize(
        address admin_,
        string memory name_,
        string memory symbol_,
        string memory uri_
    ) internal virtual;

    function _setType(uint96 type_) internal {
        _type = type_;
    }

    function _setVersion(bytes32 version_) internal {
        _version = version_;
    }

    function getVersion() external view override returns (bytes32) {
        return _version;
    }

    function getType() external view override returns (uint96) {
        return _type;
    }
}
