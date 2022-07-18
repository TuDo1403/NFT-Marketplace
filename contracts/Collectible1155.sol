// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

import "./base/NFTBase.sol";
import "./base/token/ERC1155/extensions/ERC1155Permit.sol";
import "./base/token/ERC1155/extensions/ERC1155Royalty.sol";
import "./base/token/ERC1155/extensions/ERC1155SupplyLite.sol";
import "./base/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "./base/token/ERC1155/extensions/ERC1155BurnableLite.sol";
import "./base/NFTFreezable.sol";

import "./interfaces/ISemiNFT.sol";

contract Collectible1155 is
    ISemiNFT,
    NFTBase,
    NFTFreezable,
    ERC1155Permit,
    ERC1155Royalty,
    ERC1155URIStorage,
    ERC1155SupplyLite,
    ERC1155BurnableLite
{
    // keccak256("URI_SETTER_ROLE")
    bytes32 public constant URI_SETTER_ROLE =
        0x7804d923f43a17d325d77e781528e0793b2edd9890ab45fc64efd7b4b427744c;

    string public name;
    string public symbol;

    constructor(
        address admin_,
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    )
        ERC1155Permit(name_, VERSION)
        NFTBase(admin_, owner_, 1155)
    {
        if (bytes(name_).length > 32 || bytes(symbol_).length > 32) {
            revert ERC1155__StringTooLong();
        }
        name = name_;
        symbol = symbol_;
        _setBaseURI(baseURI_);
        _grantRole(URI_SETTER_ROLE, owner_);
    }

    function mint(uint256 tokenId_, uint256 amount_) external override {
        _onlyExists(tokenId_);
        _notFrozenToken(tokenId_);
        address sender = _msgSender();
        _onlyCreatorOrHasRole(sender, tokenId_, MINTER_ROLE);
        _mint(sender, tokenId_, amount_, "");
    }

    function mint(address to_, ReceiptUtil.Item memory item_)
        external
        override
        onlyMarketplaceOrMinter
    {
        _onlyUnexists(item_.tokenId);
        _mint(to_, item_.tokenId, item_.amount, "");

        if (bytes(item_.tokenURI).length != 0) {
            _setURI(item_.tokenId, item_.tokenURI);
        }
    }

    function mintBatch(
        uint256[] calldata tokenIds_,
        uint256[] calldata amounts_
    ) external override {
        //uint256 length = amounts_.length;
        address sender = _msgSender();
        _checkRole(MINTER_ROLE, sender);
        for (uint256 i; i < amounts_.length; ) {
            uint256 tokenId = tokenIds_[i];
            _onlyExists(tokenId);
            _notFrozenToken(tokenId);
            _onlyCreator(sender, tokenId);
            unchecked {
                ++i;
            }
        }
        _mintBatch(sender, tokenIds_, amounts_, "");
    }

    function mintBatch(address to_, ReceiptUtil.Bulk memory bulk_)
        external
        override
        onlyMarketplaceOrMinter
    {
        string[] memory tokenURIs = bulk_.tokenURIs;
        uint256[] memory tokenIds = bulk_.tokenIds;
        //uint256 length = tokenURIs.length;
        _lengthMustMatch(tokenURIs.length, tokenIds.length);

        for (uint256 i; i < tokenURIs.length; ) {
            _onlyUnexists(tokenIds[i]);
            if (bytes(tokenURIs[i]).length != 0) {
                _setURI(tokenIds[i], tokenURIs[i]);
            }
            unchecked {
                ++i;
            }
        }
        _mintBatch(to_, tokenIds, bulk_.amounts, "");
    }

    function setTokenURI(uint256 tokenId_, string calldata tokenURI_)
        external
        notFrozenToken(tokenId_)
    {
        _onlyCreatorOrHasRole(_msgSender(), tokenId_, URI_SETTER_ROLE);
        _setURI(tokenId_, tokenURI_);
        _freezeToken(tokenId_);
    }

    function uri(uint256 tokenId)
        public
        view
        override(ERC1155, ERC1155URIStorage)
        returns (string memory)
    {
        return ERC1155URIStorage.uri(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Lite, ERC1155Royalty, IERC165, NFTBase)
        returns (bool)
    {
        return
            type(IERC165).interfaceId == interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setBaseURI(string calldata baseURI_)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setBaseURI(baseURI_);
        _freezeBaseURI();
    }

    function freezeBaseURI()
        external
        virtual
        override
        notFrozenBase
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        super._freezeBaseURI();
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155SupplyLite) {
        ERC1155SupplyLite._beforeTokenTransfer(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Royalty) {
        ERC1155Royalty._afterTokenTransfer(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    function freezeToken(uint256 tokenId_)
        external
        override
        onlyCreator(_msgSender(), tokenId_)
    {
        _freezeToken(tokenId_);
    }

    function _freezeBaseURI() internal virtual override {
        super._freezeBaseURI();
        emit PermanentURI(0, uri(0));
    }

    function _freezeToken(uint256 tokenId_) internal virtual override {
        super._freezeToken(tokenId_);
        emit PermanentURI(tokenId_, uri(tokenId_));
    }

    function _onlyCreatorOrHasRole(
        address sender_,
        uint256 tokenId_,
        bytes32 role_
    ) internal view virtual {
        if (!_isCreatorOf(sender_, tokenId_) && !hasRole(role_, sender_)) {
            revert ERC1155__Unauthorized();
        }
    }

    function _onlyUnexists(uint256 tokenId_) internal view virtual {
        if (exists(tokenId_)) {
            revert ERC1155__TokenExisted();
        }
    }

    function _onlyExists(uint256 tokenId_) internal view virtual {
        if (!exists(tokenId_)) {
            revert ERC1155__TokenUnexisted();
        }
    }
}
