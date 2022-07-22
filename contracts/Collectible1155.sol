// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "./base/NFTBase.sol";
import "./base/TokenFreezable.sol";
import "./base/token/ERC1155/extensions/ERC1155Permit.sol";
import "./base/token/ERC1155/extensions/ERC1155Royalty.sol";
import "./base/token/ERC1155/extensions/ERC1155SupplyLite.sol";
import "./base/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "./base/token/ERC1155/extensions/ERC1155BurnableLite.sol";

import "./interfaces/ISemiNFT.sol";

contract Collectible1155 is
    NFTBase,
    ISemiNFT,
    TokenFreezable,
    ERC1155Permit,
    ERC1155Royalty,
    ERC1155URIStorage,
    ERC1155SupplyLite,
    ERC1155BurnableLite
{
    //keccak256("Collectible1155_v1")
    bytes32 public constant VERSION =
        0xacedfc5229b6e6214a0c4700d2ef118b801c7cd97402548296df8a5fa50e967c;

    //keccak256("URI_SETTER_ROLE")
    bytes32 private constant URI_SETTER_ROLE =
        0x7804d923f43a17d325d77e781528e0793b2edd9890ab45fc64efd7b4b427744c;

    string public name;
    string public symbol;

    constructor() NFTBase(1155) ERC1155Lite("") {}

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
        name = name_;
        symbol = symbol_;

        _setBaseURI(baseURI_);
        _grantRole(URI_SETTER_ROLE, owner_);
        _grantRole(DEFAULT_ADMIN_ROLE, owner_);

        _initialize(admin_, owner_);
        __EIP712_init(type(Collectible1155).name, "v1");
    }

    function mint(uint256 tokenId_, uint256 amount_) external override {
        _onlyExists(tokenId_);
        _notFrozenToken(tokenId_);
        address sender = _msgSender();
        _onlyCreatorOrHasRole(sender, tokenId_, MINTER_ROLE);
        // if (sender != owner()) {
        //     revert ERC1155__Unauthorized();
        // }
        _mint(sender, tokenId_, amount_, "");
    }

    function mint(
        address to_,
        uint256 tokenId_,
        uint256 amount_,
        string memory tokenURI_
    ) external override {
        _onlyMarketplaceOrMinter();
        //_onlyUnexists(item_.tokenId);
        _mint(to_, tokenId_, amount_, "");

        if (bytes(tokenURI_).length != 0) {
            _setURI(tokenId_, tokenURI_);
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

    function mintBatch(
        address to_,
        uint256[] memory tokenIds_,
        uint256[] memory amounts_,
        string[] memory tokenURIs_
    ) external override {
        _onlyMarketplaceOrMinter();
        for (uint256 i; i < tokenURIs_.length; ) {
            if (bytes(tokenURIs_[i]).length != 0) {
                _setURI(tokenIds_[i], tokenURIs_[i]);
            }
            unchecked {
                ++i;
            }
        }
        _mintBatch(to_, tokenIds_, amounts_, "");
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

    function freezeToken(uint256 tokenId_) external override {
        _onlyCreator(_msgSender(), tokenId_);
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

    // function _onlyUnexists(uint256 tokenId_) internal view virtual {
    //     if (exists(tokenId_)) {
    //         revert ERC1155__TokenExisted();
    //     }
    // }

    function _onlyExists(uint256 tokenId_) internal view virtual {
        if (!exists(tokenId_)) {
            revert ERC1155__TokenUnexisted();
        }
    }

    function _onlyMarketplaceOrMinter() internal view {
        address sender = _msgSender();
        if (sender != admin.marketplace()) {
            _checkRole(MINTER_ROLE, sender);
        }
    }
}
