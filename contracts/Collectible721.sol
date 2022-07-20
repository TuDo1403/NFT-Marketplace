// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import "./base/NFTBase.sol";
import "./base/token/ERC721/extensions/ERC721Permit.sol";
import "./base/token/ERC721/extensions/ERC721Royalty.sol";
import "./base/token/ERC721/extensions/ERC721BurnableLite.sol";
import "./base/token/ERC721/extensions/ERC721URIStorageLite.sol";

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
    string public baseURI;

    constructor(
        address admin_,
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    )
        ERC721Lite(name_, symbol_)
        ERC721Permit(name_, "Collectible721_v1")
        NFTBase(admin_, owner_, 721)
    {
        baseURI = baseURI_;
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
        if (amount_ != 0) {
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

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorageLite, ERC721Royalty)
    {
        ERC721Royalty._burn(tokenId);
        ERC721URIStorageLite._burn(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
