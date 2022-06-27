// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

import "./Collectible.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/draft-ERC721VotesUpgradeable.sol";

/// @custom:security-contact tudm@inspirelab.io
contract Collectible721 is
    Collectible,
    ERC721Upgradeable,
    ERC721VotesUpgradeable,
    ERC721BurnableUpgradeable
{
    function _initialize(
        address admin_,
        string memory name_,
        string memory symbol_,
        string memory uri_
    ) internal override {
        _setType(721);
        _setVersion(keccak256("Collectible721v1"));

        __ERC721_init(name_, symbol_);
        __ERC721Burnable_init();
    }

    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri
    ) public onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721VotesUpgradeable) {
        super._afterTokenTransfer(from, to, tokenId);
    }

    function getVersion() external view override returns (bytes32) {}

    function getType() external view override returns (uint96) {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable, ERC721Upgradeable)
        returns (bool)
    {}
}
