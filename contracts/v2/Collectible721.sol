// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

import "./interfaces/ICollectible721.sol";
import "node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

contract Collectible721 is ICollectible721, ERC721URIStorageUpgradeable {
    // State varidables
    uint96 public constant TYPE = 721;

    address private factory;
    string private uri_;
    address private owner_;
    string private name_;
    string private symbol_;

    // Functions
    function initialize(
        address _admin,
        string calldata _uri,
        string calldata _name,
        string calldata _symbol
    ) external override {
        __ERC721_init(_name, _symbol);

        factory = _msgSender();
        uri_ = _uri;
        owner_ = _admin;
        name_ = _name;
        symbol_ = _symbol;
    }

    function mint(address to, uint256 tokenId) external override {
        _safeMint(to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId, bytes memory _data) external override {
        _safeTransfer(from, to, tokenId, _data);
    }

    function getType() external pure override returns (uint96) {
        return TYPE;
    }

    function setTokenURI(uint256 token, bytes memory uri) external override {

    }

    function freezeTokenURI(uint256) external override {

    }
}