// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "./Interfaces/ICollectible.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

error mustBeFactory();
error mustBeOwner();
error tokenMustNotBeFrozen();
error tokenAlreadyFrozen();

abstract contract Collectible is ICollectible, Initializable {
    //state varabile
    address private s_factory;
    uint88 private s_type;
    mapping(uint256 => string) public s_metaURIs;
    mapping(uint256 => bool) internal s_frozenToken;

    modifier onlyFactory(address addr) {
        if (s_factory != addr) {
            revert mustBeFactory();
        }
        _;
    }

    event TokenMinted(
        uint256 id,
        string tokenUri,
        uint256 createdTime,
        address creator
    );

    event URI(string value, uint256 indexed id);

    event PermanentURI(uint256 indexed tokenId, string uri);

    function initialize(
        address _nftCreator,
        string calldata _uri,
        string calldata _name,
        string calldata _symbol
    ) external override initializer {
        s_factory = msg.sender;
        _initialize(_nftCreator, _uri, _name, _symbol);
    }

    function _initialize(
        address _nftCreator,
        string calldata _uri,
        string calldata _name,
        string calldata _symbol
    ) internal virtual;

    function _setType(uint88 _type) internal {
        s_type = _type;
    }

    function _getType() external view returns (uint88) {
        return s_type;
    }
}
