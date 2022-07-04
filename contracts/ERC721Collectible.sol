// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "./Collectible.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

contract ERC721Collectible is Collectible, ERC721Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public s_tokenCounter;

    modifier onlyOwner(address owner) {
        if (msg.sender == owner || isApprovedForAll(owner, msg.sender)) {
            revert mustBeOwner();
        }
        _;
    }

    function _initialize(
        address _admin,
        string calldata _uri,
        string calldata _name,
        string calldata _symbol
    ) internal override {
        __ERC721_init(_name, _symbol);
        _setType(721);
    }

    //mint - call ony by the owner of the nft contract
    function mint(address to, string memory tokenUri)
        external
        onlyOwner(msg.sender)
    {
        _mint(to, tokenUri);
    }

    //Editing/Updating a token with a new uri
    // Not forzen
    // Only the owner of the NFT contract can call this function
    // emit a URI event
    function setTokenUri(uint256 tokenId, string memory uri)
        public
        onlyOwner(msg.sender)
    {
        _setTokenUri(tokenId, uri);
    }

    //Freeze a token
    // only the owner of the NFT contract can call this function
    // emit a PermanentURI event
    function freezeTokenData(uint256 tokenId) public onlyOwner(msg.sender) {
        _freezeTokenData(tokenId);
    }

    // internal functions
    function _mint(address _to, string memory tokenUri) internal {
        s_tokenCounter.increment();
        uint256 id = s_tokenCounter.current();
        s_metaURIs[id] = tokenUri;
        _safeMint(_to, id);
        emit TokenMinted(id, tokenUri, block.timestamp, _to);
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
