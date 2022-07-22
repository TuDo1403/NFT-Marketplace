// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

import "../ERC721Lite.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../../../../libraries/TokenIdGenerator.sol";

abstract contract ERC721Royalty is ERC2981, ERC721Lite {
    using TokenIdGenerator for uint256;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC165).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (from == address(0)) {
            _setTokenRoyalty(tokenId, to, uint96(tokenId.getCreatorFee()));
        }
    }
}
