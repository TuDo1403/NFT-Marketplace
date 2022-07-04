// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "./Collectible.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";

contract ERC1155Collectible is Collectible, ERC1155Upgradeable {
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
    function setTokenUri(uint256 tokenId, string memory uri) public {}

    //internal methods
    function _mint(address _to, string memory _tokenUri) internal {
        s_tokenCounter.increment();
        uint256 id = s_tokenCounter.current();
        s_metaURIs[id] = _tokenUri;
        _mint(_to, id, 1, "");
        emit TokenMinted(id, _tokenUri, block.timestamp, _to);
    }
}
