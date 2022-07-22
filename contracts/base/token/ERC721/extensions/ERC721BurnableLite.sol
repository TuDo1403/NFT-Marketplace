// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

import "../ERC721Lite.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721BurnableLite is Context, ERC721Lite {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        // require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _onlyOwnerOrApproved(_msgSender(), tokenId);
        _burn(tokenId);
    }
}
