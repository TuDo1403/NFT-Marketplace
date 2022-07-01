// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

import "node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "./interfaces/ICollectible721.sol";


/// @custom:security-contact datndt@inspirelab.io
contract Collectible721 is ERC721Upgradeable, ERC721URIStorageUpgradeable, ICollectible721
{
    // State variables
    address public factory;

    uint96 public constant TYPE = 721;

    mapping(uint256 => address) creator;

    modifier onlyFactory() {
        require(factory == _msgSender(), "Collectible721: Only Factory");
        _;
    }

    // Functional
    function initialize(
        address admin_,
        string calldata name_,
        string calldata symbol_,
        string calldata uri_
    ) external override initializer {
        __ERC721_init(name_, symbol_);
        factory = _msgSender();
    }

    function mint(address to, uint256 tokenId) external override {
        require(to != address(0), "Collectible721: Address must be not NULL!");
        _safeMint(to, tokenId);
        creator[tokenId] = to;
    }

    // function mint(address to, uint256 tokenId, uint256 amount, bytes memory data) external override {
    //     revert("Collectible721: Not support this function!");
    // }

    // function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data ) external override {
    //     revert("Collectible721: Not support this function!");
    // }

    function setTokenUri(uint256 tokenId, string memory uri) external override {
        _setTokenURI(tokenId, uri);
    }

    function freezeTokenData(uint256 id) external override {}


    function getType() external pure override returns (uint96) {
        return TYPE;
    }

    function getCreator(uint256 tokenId) external view override returns (address) {
        return creator[tokenId];
    }
}
