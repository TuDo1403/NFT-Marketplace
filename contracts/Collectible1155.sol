// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

import "./CollectibleBase.sol";

import "./interfaces/IGovernance.sol";
import "./interfaces/ICollectible1155.sol";

contract Collectible1155 is
    Initializable,
    ERC1155Supply,
    CollectibleBase,
    ERC1155Burnable,
    ERC1155URIStorage,
    ICollectible1155
{
    using Strings for uint256;
    using TokenIdGenerator for uint256;
    using TokenIdGenerator for TokenIdGenerator.Token;

    uint256 public constant TYPE = 1155;

    string public name;
    string public symbol;

    modifier onlyUnexists(uint256 tokenId_) {
        __onlyUnexists(tokenId_);
        _;
    }

    constructor(address admin_) ERC1155("") CollectibleBase(admin_) {}

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

    function setBaseURI(string calldata baseURI_)
        external
        override(CollectibleBase, ICollectible)
        onlyRole(URI_SETTER_ROLE)
        notFrozenBase
    {
        _setBaseURI(baseURI_);
        _freezeBase();
    }

    function _freezeBase() internal override notFrozenBase {
        isFrozenBase = true;
        emit PermanentURI(0, uri(0));
    }

    function setTokenURI(uint256 tokenId_, string calldata tokenURI_)
        external
        override
        onlyCreatorAndNotFrozen(tokenId_)
    {
        _setURI(tokenId_, tokenURI_);
        _freezeToken(tokenId_);
    }

    function mint(uint256 tokenId_, uint256 amount_)
        external
        override
        onlyCreatorAndNotFrozen(tokenId_)
    {
        address sender = _msgSender();
        __supplyCheck(tokenId_, amount_);
        _mint(sender, tokenId_, amount_, "");
    }

    function mint(
        address to_,
        uint256 tokenId_,
        uint256 amount_,
        string calldata tokenURI_
    ) external override onlyUnexists(tokenId_) {
        if (_msgSender() != admin.marketplace()) {
            _checkRole(MINTER_ROLE);
        }
        _setTokenRoyalty(
            tokenId_,
            tokenId_.getTokenCreator(),
            uint96(tokenId_.getCreatorFee())
        );
        _mint(to_, tokenId_, amount_, "");
        if (bytes(tokenURI_).length != 0) {
            _setURI(tokenId_, tokenURI_);
        }
    }

    function mintBatch(
        uint256[] calldata tokenIds_,
        uint256[] calldata amounts_
    ) external override onlyRole(MINTER_ROLE) {
        address sender = _msgSender();
        for (uint256 i; i < amounts_.length; ) {
            uint256 tokenId = tokenIds_[i];
            _onlyCreatorAndNotFrozen(sender, tokenId);
            __supplyCheck(tokenId, amounts_[i]);
            unchecked {
                ++i;
            }
        }
        _mintBatch(sender, tokenIds_, amounts_, "");
    }

    function mintBatch(
        address to_,
        uint256[] calldata tokenIds_,
        uint256[] calldata amounts_,
        string[] calldata tokenURIs_
    ) external override onlyRole(MINTER_ROLE) {
        for (uint256 i; i < tokenURIs_.length; ) {
            uint256 tokenId = tokenIds_[i];
            __onlyUnexists(tokenId);
            _setTokenRoyalty(
                tokenId,
                tokenId.getTokenCreator(),
                uint96(tokenId.getCreatorFee())
            );
            string memory _tokenURI = tokenURIs_[i];
            if (bytes(_tokenURI).length != 0) {
                _setURI(tokenId, _tokenURI);
            }
            unchecked {
                ++i;
            }
        }
        _mintBatch(to_, tokenIds_, amounts_, "");
    }

    function transferSingle(
        address from_,
        address to_,
        uint256 amount_,
        uint256 tokenId_
    ) external override onlyMarketplace {
        _safeTransferFrom(from_, to_, tokenId_, amount_, "");
    }

    function transferBatch(
        address from_,
        address to_,
        uint256[] memory amounts_,
        uint256[] memory tokenIds_
    ) external override onlyMarketplace {
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
        }
    }

    function tokenURI(uint256 tokenId_)
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
        override(ERC1155, CollectibleBase)
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

    function _freezeToken(uint256 tokenId_) internal override {
        super._freezeToken(tokenId_);
        emit PermanentURI(tokenId_, uri(tokenId_));
    }

    function __supplyCheck(uint256 tokenId_, uint256 amount_) private view {
        if (amount_ > 2**TokenIdGenerator.SUPPLY_BIT - 1) {
            revert ERC1155__AllocationExceeds();
        }
        uint256 maxSupply = tokenId_.getTokenMaxSupply();
        if (maxSupply != 0) {
            unchecked {
                if (amount_ + totalSupply(tokenId_) > maxSupply) {
                    revert ERC1155__AllocationExceeds();
                }
            }
        }
    }

    function __onlyUnexists(uint256 tokenId_) private view {
        if (exists(tokenId_)) {
            revert NFT__TokenExisted();
        }
    }
}
