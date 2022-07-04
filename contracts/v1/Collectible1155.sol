// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

import "./interfaces/ICollectible1155.sol";
import "node_modules/@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";


/// @custom:security-contact datndt@inspirelab.io
contract Collectible1155 is ICollectible1155, ERC1155URIStorageUpgradeable
{
    // State variables
    address public factory;

    string public name;
    string public symbol;

    mapping(uint256 => address) creator;

    uint96 public constant TYPE = 1155;

    // Modifier
    modifier onlyFactory() {
        require(factory == _msgSender(), "Collectible1155: Only Factory");
        _;
    }

    // Functional
    function initialize(
        address admin_,
        string calldata uri_,
        string calldata name_,
        string calldata symbol_
    ) external override initializer {
        __ERC1155_init(uri_);
        name = name_;
        symbol = symbol_;
        factory = _msgSender();
    }

    // Chu so huu hop dong moi duoc mint nft so huu?
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) external override {
        _mint(to, tokenId, amount, data);

        // Assign creator address for tokenId
        creator[tokenId] = to;
    }

    // function mint(address to, uint256 tokenId) external override {
    //     revert("Collectible1155: Not support this function!");
    // }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        require(to != address(0), "Collectible1155: Address must be not NULL!");
        _mintBatch(to, ids, amounts, data);

        // Assign creator address for tokenId
        for (uint256 i = 0; i < ids.length; i++) {
            creator[ids[i]] = to;
        }
    }

    function setTokenUri(uint256 tokenId, string memory uri) external override {
        _setURI(tokenId, uri);
    }

    function freezeTokenData(uint256 id) external override {}

    function getType() external pure override returns (uint96) {
        return TYPE;
    }

    function getCreator(uint256 tokenId) external view override returns (address) {
        return creator[tokenId];
    }
}

    // function uri(uint256 tokenId) external override returns (string) {}

    // function balanceOf(address account, uint256 tokenId) external override returns (uint256) {}

    // function balanceOfBatch(address accounts, uint256 ids) external override returns (uint256) {}

    // function setApprovalForAll(address operator, bool approved) external override {}

    // function isApprovedForAll(address account, address operator) external override returns (bool) {}

    // function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data) external override {}

    // function safeBatchTransferFrom(address from, address to, uint256 ids, uint256 amounts, bytes memory data) external override {}
    