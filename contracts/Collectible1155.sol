// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

import "./CollectibleBase.sol";
import "./ERC1155Permit.sol";

import "./interfaces/IGovernance.sol";
import "./interfaces/ICollectible1155.sol";

contract Collectible1155 is
    ERC1155Supply,
    ERC1155Permit,
    CollectibleBase,
    ERC1155Burnable,
    ERC1155URIStorage,
    ICollectible1155
{
    using Strings for uint256;
    using Counters for Counters.Counter;
    using TokenIdGenerator for uint256;
    using TokenIdGenerator for TokenIdGenerator.Token;

    uint256 public constant TYPE = 1155;

    string public name;
    string public symbol;

    mapping(address => Counters.Counter) public nonces;

    modifier onlyUnexists(uint256 tokenId_) {
        __onlyUnexists(tokenId_);
        _;
    }

    constructor(
        address admin_,
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) ERC1155Permit(name_, VERSION) CollectibleBase(admin_) {
        if (bytes(name_).length > 32 || bytes(symbol_).length > 32) {
            revert ERC1155__StringTooLong();
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

    function mint(address to_, ReceiptUtil.Item memory item_)
        external
        override
    {
        uint256 tokenId = item_.tokenId;
        __onlyUnexists(tokenId);
        if (_msgSender() != admin.marketplace()) {
            _checkRole(MINTER_ROLE);
        }
        _setTokenRoyalty(
            tokenId,
            tokenId.getTokenCreator(),
            uint96(tokenId.getCreatorFee())
        );
        _mint(to_, tokenId, item_.amount, "");

        string memory _tokenURI = item_.tokenURI;
        if (bytes(_tokenURI).length != 0) {
            _setURI(tokenId, _tokenURI);
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

    function mintBatch(address to_, ReceiptUtil.Bulk memory bulk_)
        external
        override
        onlyRole(MINTER_ROLE)
    {
        for (uint256 i; i < bulk_.tokenURIs.length; ) {
            uint256 tokenId = bulk_.tokenIds[i];
            __onlyUnexists(tokenId);
            _setTokenRoyalty(
                tokenId,
                tokenId.getTokenCreator(),
                uint96(tokenId.getCreatorFee())
            );
            string memory _tokenURI = bulk_.tokenURIs[i];
            if (bytes(_tokenURI).length != 0) {
                _setURI(tokenId, _tokenURI);
            }
            unchecked {
                ++i;
            }
        }
        _mintBatch(to_, bulk_.tokenIds, bulk_.amounts, "");
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
        override(ERC1155, CollectibleBase, IERC165)
        returns (bool)
    {
        return
            type(ICollectible1155).interfaceId == interfaceId ||
            type(IERC165).interfaceId == interfaceId ||
            ERC1155.supportsInterface(interfaceId) ||
            CollectibleBase.supportsInterface(interfaceId);
    }

    function _burn(
        address from_,
        uint256 id_,
        uint256 amount_
    ) internal override {
        super._burn(from_, id_, amount_);
        _resetTokenRoyalty(id_);
    }

    function _useNonce(address owner_)
        internal
        override
        returns (uint256 nonce)
    {
        nonce = nonces[owner_].current();
        nonces[owner_].increment();
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        ERC1155Supply._beforeTokenTransfer(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    function _freezeToken(uint256 tokenId_) internal override {
        super._freezeToken(tokenId_);
        emit PermanentURI(tokenId_, uri(tokenId_));
    }

    function __supplyCheck(uint256 tokenId_, uint256 amount_) private view {
        // if (amount_ > 2**TokenIdGenerator.SUPPLY_BIT - 1) {
        //     revert ERC1155__AllocationExceeds();
        // }
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
            revert ERC1155__TokenExisted();
        }
    }
}
