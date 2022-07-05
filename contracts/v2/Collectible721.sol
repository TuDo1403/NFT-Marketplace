// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

import "./interfaces/ICollectible721.sol";
import "node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

/// @title Triton ERC721 token
/// @author Dat Nguyen (datndt@inspirelab.io)

contract Collectible721 is ICollectible721, ERC721URIStorageUpgradeable {
    uint96 public constant TYPE = 721;
    address private _factory;
    string private _uri;
    address private _owner;
    string private _name;
    string private _symbol;

    /**
     * @notice Initialize function inheritance ICollectible.sol
     * @param _admin NFT Contract owner
     * @param _uri URI of NFT
     * @param _name Name of NFT
     * @param _symbol Symboy of NFT
     */
    function initialize(
        address admin,
        string calldata uri,
        string calldata name,
        string calldata symbol
    ) external override {
        __ERC721_init(name, symbol);

        _factory = _msgSender();
        _uri = uri;
        _owner = admin;
        _name = name;
        _symbol = symbol;
    }

    /**
     * @notice Mint a new token
     * @param to Address of new minted token
     * @param tokenId ID of minted token
     */
    function mint(address to, uint256 tokenId) external override {
        _safeMint(to, tokenId);
    }

    /**
     * @notice Transfer NFT from "from" to "to"
     * @param from Address of sender
     * @param to Address of recicever
     * @param tokenId ID of token
     * @param data ... */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external override {
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @notice Get type of Collectible
     * @return Type of NFT (uint96)
     */
    function getType() external pure override returns (uint96) {
        return TYPE;
    }

    /**
     * @notice Set the token URI
     * @param tokenId Token ID need to set URI
     * @param uri New URI token
     */
    function setTokenURI(uint256 token, bytes memory uri) external override {}

    /**
     * @notice Freeze token URI
     * @param tokenId Token ID need to freeze URI
     */
    function freezeTokenURI(uint256) external override {}
}