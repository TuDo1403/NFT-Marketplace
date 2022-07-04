// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

import "./interfaces/ICollectible1155.sol";
import "node_modules/@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";

contract Collectible1155 is ICollectible1155, ERC1155URIStorageUpgradeable {
    // State varidables
    uint96 public constant TYPE = 1155;

    address private factory;
    address private owner;
    string private name;
    string private symbol;

    // Functions
    function initialize(
        address _admin,
        string calldata _uri,
        string calldata _name,
        string calldata _symbol
    ) external override {
        __ERC1155_init(_uri);

        factory = _msgSender();
        owner = _admin;
        name = _name;
        symbol = _symbol;
    }

    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) external override {
        _mint(to, tokenId, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        _mintBatch(to, ids, amounts, data);
    }

    function getType() external override {
        return TYPE;
    }

    function transferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory _data) external override {
        _safeTransferFrom(from, to, tokenId, amount, _data);
    }id
    function setTokenURI(uint256 token, bytes memory uri) external override {}

    function freezeTokenURI(uint256) external override {}
}
