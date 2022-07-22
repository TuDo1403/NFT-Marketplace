// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "./base/NFTBase.sol";
import "./base/token/ERC721/extensions/ERC721Permit.sol";
import "./base/token/ERC721/extensions/ERC721Royalty.sol";
import "./base/token/ERC721/extensions/ERC721BurnableLite.sol";
import "./base/token/ERC721/extensions/ERC721URIStorageLite.sol";
import "hardhat/console.sol";
import "./interfaces/INFT.sol";

contract Collectible721 is
    INFT,
    NFTBase,
    ERC721Permit,
    ERC721Royalty,
    ERC721BurnableLite,
    ERC721URIStorageLite
{
    //keccak256("Collectible721_v1");
    bytes32 public constant VERSION =
        0x9de63d708ee09a8f840a47cc975044d19e4c3537fe6b165971d829e6619e0ffa;

    string private _name;
    string private _symbol;
    string private baseURI;

    constructor() NFTBase(721) {}

    function initialize(
        address admin_,
        address owner_,
        string calldata name_,
        string calldata symbol_,
        string calldata baseURI_
    ) external override initializer {
        if (bytes(name_).length > 32 || bytes(symbol_).length > 32) {
            revert NFT__StringTooLong();
        }
        _name = name_;
        _symbol = symbol_;
        baseURI = baseURI_;

        _initialize(admin_, owner_);
        __EIP712_init(type(Collectible721).name, "v1");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Royalty) {
        ERC721Royalty._beforeTokenTransfer(from, to, tokenId);
    }

    function mint(
        address to_,
        uint256 tokenId_,
        uint256 amount_,
        string memory tokenURI_
    ) external override {
        address sender = _msgSender();

        if (sender != admin.marketplace()) {
            _checkRole(MINTER_ROLE, sender);
        }
        if (amount_ != 1) {
            revert ERC721__InvalidInput();
        }
        _safeMint(to_, tokenId_);
        _setTokenURI(tokenId_, tokenURI_);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Royalty, IERC165, NFTBase)
        returns (bool)
    {
        return
            type(IERC165).interfaceId == interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Lite, ERC721URIStorageLite)
        returns (string memory)
    {
        return ERC721URIStorageLite.tokenURI(tokenId);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorageLite, ERC721Royalty)
    {
        ERC721Royalty._burn(tokenId);
        ERC721URIStorageLite._burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
