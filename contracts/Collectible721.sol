// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

import "./base/NFTBase.sol";
import "./base/token/ERC721/extensions/ERC721BurnableLite.sol";
import "./base/token/ERC721/extensions/ERC721URIStorageLite.sol";
import "./base/token/ERC721/extensions/ERC721Permit.sol";
import "./base/token/ERC721/extensions/ERC721Royalty.sol";

import "./interfaces/INFT.sol";

contract Collectible721 is
    INFT,
    NFTBase,
    ERC721Permit,
    ERC721Royalty,
    ERC721BurnableLite,
    ERC721URIStorageLite
{
    string public baseURI;

    constructor(
        address admin_,
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    )
        ERC721Lite(name_, symbol_)
        ERC721Permit(name_, VERSION)
        NFTBase(admin_, owner_, 721)
    {
        if (bytes(name_).length > 32 || bytes(symbol_).length > 32) {
            revert ERC721__StringTooLong();
        }
        baseURI = baseURI_;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Royalty) {
        ERC721Royalty._beforeTokenTransfer(from, to, tokenId);
    }

    function mint(address to_, ReceiptUtil.Item memory item_)
        public
        override
        onlyMarketplaceOrMinter
    {
        uint256 tokenId = item_.tokenId;
        if (_exists(tokenId)) {
            revert ERC721__TokenExisted();
        }
        _safeMint(to_, tokenId);
        _setTokenURI(tokenId, item_.tokenURI);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Royalty, NFTBase, IERC165)
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
