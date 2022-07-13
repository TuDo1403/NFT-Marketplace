// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "./CollectibleBase.sol";

import "./interfaces/IGovernance.sol";
import "./interfaces/ICollectible.sol";

contract Collectible721 is
    ICollectible,
    ERC721Burnable,
    CollectibleBase,
    ERC721URIStorage
{
    using Strings for uint256;
    using TokenIdGenerator for uint256;

    uint256 public constant TYPE = 721;

    string public baseURI;

    modifier onlyUnique(uint256 amount_) {
        if (amount_ != 1) {
            revert NFT__InvalidInput();
        }
        _;
    }

    constructor(
        address admin_,
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) ERC721(name_, symbol_) CollectibleBase(admin_) {
        if (bytes(name_).length > 32 || bytes(symbol_).length > 32) {
            revert NFT__StringTooLong();
        }
        _setBaseURI(baseURI_);
        _grantRole(MINTER_ROLE, owner_);
        _grantRole(URI_SETTER_ROLE, owner_);
    }

    function transferSingle(
        address from_,
        address to_,
        uint256 amount_,
        uint256 tokenId_
    ) external override onlyUnique(amount_) onlyMarketplace {
        _safeTransfer(from_, to_, tokenId_, "");
    }

    function setBaseURI(string calldata baseURI_)
        external
        override(CollectibleBase, ICollectible)
        onlyRole(URI_SETTER_ROLE)
        notFrozenBase
    {
        _setBaseURI(baseURI_);
        _freezeBase();
    }

    function setTokenURI(uint256 tokenId_, string calldata tokenURI_)
        external
        override
        onlyCreatorAndNotFrozen(tokenId_)
    {
        _setTokenURI(tokenId_, tokenURI_);
        _freezeToken(tokenId_);
    }

    function isMintedBefore(
        address seller_,
        uint256 tokenId_,
        uint256 amount_
    ) external view override onlyUnique(amount_) returns (bool minted) {
        if (seller_ != tokenId_.getTokenCreator()) {
            if (_isApprovedOrOwner(seller_, tokenId_)) {
                revert NFT__Unauthorized();
            }
            minted = true;
        }
    }

    function mint(
        address to_,
        uint256 tokenId_,
        uint256 amount_,
        string memory tokenURI_
    ) public onlyUnique(amount_) onlyRole(MINTER_ROLE) {
        if (_exists(tokenId_)) {
            revert NFT__TokenExisted();
        }
        _setTokenRoyalty(
            tokenId_,
            tokenId_.getTokenCreator(),
            uint96(tokenId_.getCreatorFee())
        );
        _safeMint(to_, tokenId_);
        _setTokenURI(tokenId_, tokenURI_);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage, ICollectible)
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert NFT__InvalidInput();
        }
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, CollectibleBase)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function _freezeBase() internal virtual override notFrozenBase {
        isFrozenBase = true;
        emit PermanentURI(0, baseURI);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _setBaseURI(string memory baseURI_) internal {
        baseURI = baseURI_;
    }
}
