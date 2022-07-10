// SPDX-License-Identifier: Unlisened
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
//import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

import "./interfaces/IGovernance.sol";
import "./interfaces/ICollectible1155.sol";

//Pausable,
contract Collectible1155 is
    Initializable,
    AccessControl,
    ERC1155Supply,
    ERC1155Burnable,
    ERC1155URIStorage,
    ICollectible1155
{
    using Strings for uint256;
    using TokenIdGenerator for uint256;
    using TokenIdGenerator for TokenIdGenerator.Token;

    bool public isFrozenBase;

    IGovernance public immutable admin;

    bytes32 public constant TYPE = keccak256("ERC1155");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");

    string public name;
    string public symbol;

    mapping(uint256 => bool) public frozenTokens;

    modifier onlyCreatorAndNotFrozen(uint256 tokenId_) {
        __onlyCreatorAndNotFrozen(_msgSender(), tokenId_);
        _;
    }

    modifier notFrozenBase() {
        if (isFrozenBase) {
            revert ERC1155__FrozenBase();
        }
        _;
    }

    constructor(address admin_) ERC1155("") {
        admin = IGovernance(admin_);
    }

    //283198
    function initialize(
        address owner_,
        string calldata name_,
        string calldata symbol_,
        string calldata baseURI_
    ) external override initializer {
        if (bytes(name_).length > 32 || bytes(symbol_).length > 32) {
            revert NFT__StringTooLong();
        }
        _setBaseURI(baseURI_);

        name = name_;
        symbol = symbol_;
        _grantRole(MINTER_ROLE, owner_);
        _grantRole(URI_SETTER_ROLE, owner_);
    }

    function freezeToken(uint256 tokenId_)
        external
        override
        onlyCreatorAndNotFrozen(tokenId_)
    {
        __freezeToken(tokenId_);
    }

    function setBaseURI(string calldata baseURI_)
        external
        override
        onlyRole(URI_SETTER_ROLE)
    {
        // if (isFrozenBase) {
        //     revert ERC1155__FrozenBase();
        // }
        _setBaseURI(baseURI_);
    }

    function freezeBase()
        external
        override
        onlyRole(URI_SETTER_ROLE)
        notFrozenBase
    {
        isFrozenBase = true;
        emit PermanentURI(0, uri(0));
    }

    function setTokenURI(uint256 tokenId_, string calldata tokenURI_)
        external
        override
        onlyCreatorAndNotFrozen(tokenId_)
    {
        _setURI(tokenId_, tokenURI_);
        __freezeToken(tokenId_);
    }

    function mint(uint256 tokenId_, uint256 amount_) external override {
        address sender = _msgSender();
        __onlyCreatorAndNotFrozen(sender, tokenId_);
        __supplyCheck(tokenId_, amount_);
        _mint(sender, tokenId_, amount_, "");
    }

    function mint(
        uint256 amount_,
        TokenIdGenerator.Token calldata token_,
        string calldata tokenURI_
    ) external override onlyRole(MINTER_ROLE) {
        uint256 tokenId = token_.createTokenId();
        __supplyCheck(tokenId, amount_);
        __mint(_msgSender(), tokenId, amount_, tokenURI_);
    }

    function lazyMintSingle(
        address to_,
        uint256 tokenId_,
        uint256 amount_,
        string calldata tokenURI_
    ) external override onlyRole(MINTER_ROLE) {
        __mint(to_, tokenId_, amount_, tokenURI_);
    }

    function mintBatch(
        uint256[] calldata tokenIds_,
        uint256[] calldata amounts_
    ) external override {
        address sender = _msgSender();
        for (uint256 i; i < amounts_.length; ) {
            __onlyCreatorAndNotFrozen(sender, tokenIds_[i]);
            __supplyCheck(tokenIds_[i], amounts_[i]);
            unchecked {
                ++i;
            }
        }
        _mintBatch(sender, tokenIds_, amounts_, "");
    }

    function mintBatch(
        uint256[] calldata amounts_,
        string[] calldata tokenURIs_,
        TokenIdGenerator.Token[] calldata tokens_
    ) external override onlyRole(MINTER_ROLE) {
        if (tokenURIs_.length != tokens_.length) {
            revert ERC1155__LengthMismatch();
        }
        address _owner = _msgSender();
        uint256[] memory tokenIds;

        for (uint256 i; i < tokens_.length; ) {
            if (tokens_[i]._creator != _owner) {
                revert NFT__Unauthorized();
            }
            tokenIds[i] = tokens_[i].createTokenId();
            __supplyCheck(tokenIds[i], amounts_[i]);

            if (bytes(tokenURIs_[i]).length != 0) {
                _setURI(tokenIds[i], tokenURIs_[i]);
            }
            unchecked {
                ++i;
            }
        }

        _mintBatch(_owner, tokenIds, amounts_, "");
    }

    function lazyMintBatch(
        address to_,
        uint256[] calldata tokenIds_,
        uint256[] calldata amounts_,
        string[] calldata tokenURIs_
    ) external override onlyRole(MINTER_ROLE) {
        _mintBatch(to_, tokenIds_, amounts_, "");
        for (uint256 i; i < tokenURIs_.length; ) {
            if (bytes(tokenURIs_[i]).length != 0) {
                _setURI(tokenIds_[i], tokenURIs_[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    function transferSingle(
        address from_,
        address to_,
        uint256 amount_,
        uint256 tokenId_
    ) external override {
        if (_msgSender() != admin.marketplace()) {
            revert NFT__Unauthorized();
        }
        _safeTransferFrom(from_, to_, tokenId_, amount_, "");
    }

    function transferBatch(
        address from_,
        address to_,
        uint256[] memory amounts_,
        uint256[] memory tokenIds_
    ) external override {
        if (_msgSender() != admin.marketplace()) {
            revert NFT__Unauthorized();
        }
        _safeBatchTransferFrom(from_, to_, tokenIds_, amounts_, "");
    }

    function isMintedBefore(
        address seller_,
        uint256 tokenId_,
        uint256 amount_
    ) external view override returns (bool minted) {
        if (seller_ != tokenId_.getTokenCreator()) {
            // token must be minted before or seller must have token
            uint256 sellerBalance = balanceOf(seller_, tokenId_);
            if (
                sellerBalance == 0 ||
                amount_ > sellerBalance ||
                !exists(tokenId_)
            ) {
                revert NFT__Unauthorized();
            }
            minted = true;
        } else {
            minted = false;
        }
    }

    function getTokenURI(uint256 tokenId_)
        external
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    bytes(uri(tokenId_)),
                    bytes(tokenId_.toString())
                )
            );
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
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function __freezeToken(uint256 tokenId_) private {
        frozenTokens[tokenId_] = true;
        emit PermanentURI(tokenId_, uri(tokenId_));
    }

    function __mint(
        address to_,
        uint256 tokenId_,
        uint256 amount_,
        string calldata tokenURI_
    ) private {
        _mint(to_, tokenId_, amount_, "");
        if (bytes(tokenURI_).length != 0) {
            _setURI(tokenId_, tokenURI_);
        }
    }

    function __supplyCheck(uint256 tokenId_, uint256 amount_) private view {
        if (amount_ > 2**TokenIdGenerator.SUPPLY_BIT - 1) {
            revert NFT__Overflow();
        }
        uint256 maxSupply = tokenId_.getTokenMaxSupply();
        if (maxSupply != 0) {
            unchecked {
                if (amount_ + totalSupply(tokenId_) > maxSupply) {
                    revert NFT__Overflow();
                }
            }
        }
    }

    function __onlyCreatorAndNotFrozen(address sender_, uint256 tokenId_)
        private
        view
    {
        if (sender_ != tokenId_.getTokenCreator()) {
            revert NFT__Unauthorized();
        }
        if (frozenTokens[tokenId_]) {
            revert ERC1155__FrozenToken();
        }
    }
}