// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

import "./interfaces/ICollectible1155.sol";
import "node_modules/@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";

/// @title Triton ERC1155 token
/// @author Dat Nguyen (datndt@inspirelab.io)

contract Collectible1155 is ICollectible1155, ERC1155URIStorageUpgradeable {
    uint96 public constant TYPE = 1155;

    address private _factory;
    address private _owner;
    string private _name;
    string private _symbol;
    string private _uri;

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
        __ERC1155_init(uri);

        _factory = _msgSender();
        _owner = admin;
        _name = name;
        _symbol = symbol;
    }

    /**
     * @notice Mint a new token
     * @param to Address of a minted token owner
     * @param tokenId Id of minted token
     * @param amount Amount of minted token
     * @param data ...abi */
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) external override {
        _mint(to, tokenId, amount, data);
    }

    /**
     * @notice Mint a batch of tokens
     * @param to Address of minted token batch
     * @param ids Id array of token batch
     * @param amounts Amount array of token ids
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @notice Get type of Collectible
     * @return Type of NFT (uint96)
     */
    function getType() external pure override returns (uint96) {
        return TYPE;
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
        uint256 amount,
        bytes memory _data
    ) external override {
        _safeTransferFrom(from, to, tokenId, amount, _data);
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
