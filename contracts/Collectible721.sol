// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

import "node_modules/@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./interfaces/ICollectible721.sol";


/// @custom:security-contact datndt@inspirelab.io
contract Collectible721 is ERC721Upgradeable, ICollectible721
{
    // State variables
    address public factory;

    uint96 public constant TYPE = 721;
    bytes32 public constant VERSION = keccak256("Collectible721v1");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");

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

    function mint(address to, uint256 tokenId, uint256 amount, bytes memory data) external override {
        revert("Collectible721: Not support this function!");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data ) external override {
        revert("Collectible721: Not support this function!");
    }

    function getType() external pure override returns (uint96) {
        return TYPE;
    }

    function getCreator(uint256 tokenId) external view override returns (address) {
        return creator[tokenId];
    }
}
