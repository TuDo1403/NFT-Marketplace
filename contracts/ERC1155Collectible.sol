// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "./Collectible.sol";
import "./Interfaces/IERC1155Collectible.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ERC1155Collectible is
    Collectible,
    IERC1155Collectible,
    ERC1155Upgradeable,
    OwnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public s_tokenCounter;

    function _initialize(
        address _admin,
        string calldata _uri,
        string calldata _name,
        string calldata _symbol
    ) internal override {
        __ERC1155_init(_uri);
        _setType(1155);
    }

    //mint - call ony by the owner of the nft contract
    function mint(address to, string memory tokenUri) external {
        _mint(to, tokenUri);
    }

    function mintBatch(address to, string[] memory tokenUris) external {
        uint256 tokensNumber = tokenUris.length;
        for (uint256 i = 0; i < tokensNumber; i++) {
            _mint(to, tokenUris[i]);
        }
    }

    //Editing/Updating a token with a new uri
    // Not forzen
    // Only the owner of the NFT contract can call this function
    // emit a URI event
    function setTokenUri(uint256 tokenId, string memory uri) public onlyOwner {
        _setTokenUri(tokenId, uri);
    }

    //Freeze a token
    // only the owner of the NFT contract can call this function
    // emit a PermanentURI event
    function freezeTokenData(uint256 tokenId) public onlyOwner {
        _freezeTokenData(tokenId);
    }

    //internal methods
    function _mint(address _to, string memory _tokenUri) internal {
        s_tokenCounter.increment();
        uint256 id = s_tokenCounter.current();
        s_metaURIs[id] = _tokenUri;
        _mint(_to, id, 1, "");
        emit Token1155Minted(id, _tokenUri, block.timestamp, _to);
    }

    function _setTokenUri(uint256 _tokenId, string memory _uri) internal {
        if (s_frozenToken[_tokenId] == true) {
            revert tokenMustNotBeFrozen();
        }
        s_metaURIs[_tokenId] = _uri;
        emit URI(_uri, _tokenId);
    }

    function _freezeTokenData(uint256 _tokenId) internal {
        if (s_frozenToken[_tokenId] == true) {
            revert tokenAlreadyFrozen();
        }
        s_frozenToken[_tokenId] = true;
        emit PermanentURI(_tokenId, s_metaURIs[_tokenId]);
    }
}