// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "./interfaces/IFactory.sol";
import "./interfaces/ICollectible.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Factory is IFactory, OwnableUpgradeable {
    using ClonesUpgradeable for address;

    bytes32 public constant VERSION = keccak256("Factory1155_v1");

    modifier validAddress(address _address) {
        require(_address != address(0), "Factory1155: invalid address");
        _;
    }

    function initialize() external initializer {
        __Ownable_init();
    }

    function deployCollectible(address _implement, Settings calldata _settings)
        external
        override
        validAddress(_implement)
        returns (address deployedAddress)
    {
        deployedAddress = _deployCollectible(
            _msgSender(),
            _implement,
            _settings
        );
    }

    function _deployCollectible(
        address _deployer,
        address _implement,
        Settings memory _settings
    ) internal returns (address deployedAddress) {
        bytes32 salt = bytes32(
            keccak256(
                abi.encodePacked(
                    _settings.name,
                    _settings.symbol,
                    _settings.uri,
                    VERSION
                )
            )
        );
        deployedAddress = _implement.cloneDeterministic(salt);
        ICollectible instance = ICollectible(deployedAddress);
        instance.initialize({
            manager: _deployer,
            name: _settings.name,
            symbol: _settings.symbol,
            uri: _settings.uri
        });
        emit TokenDeployed({
            deployedAddress: deployedAddress,
            deployer: _deployer,
            version: instance.getVersion(),
            uri: _settings.uri,
            name: _settings.name,
            symbol: _settings.symbol,
            createdTime: block.timestamp
        });
    }

    function deployMultipleCollectibles(
        address[] calldata _deployers,
        address[] calldata _implements,
        Settings[] calldata _settings
    ) external override returns (address[] memory deployedAddresses) {
        require(
            _deployers.length == _implements.length &&
                _implements.length == _settings.length,
            "Factory: invalid arguments"
        );

        uint256 numCalls = _implements.length;

        for (uint256 i = 0; i < numCalls; ) {
            deployedAddresses[i] = _deployCollectible(
                _deployers[i],
                _implements[i],
                _settings[i]
            );
            unchecked {
                ++i;
            }
        }
    }
}
