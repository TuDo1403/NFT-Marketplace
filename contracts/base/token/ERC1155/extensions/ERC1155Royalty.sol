// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "../ERC1155Lite.sol";

import "../../../../libraries/TokenIdGenerator.sol";

abstract contract ERC1155Royalty is ERC2981, ERC1155Lite {
    using TokenIdGenerator for uint256;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Lite, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);
        //uint256 length = ids.length;
        if (from == address(0)) {
            for (uint256 i; i < ids.length; ) {
                uint256 tokenId = ids[i];
                _setTokenRoyalty(tokenId, to, uint96(tokenId.getCreatorFee()));
                unchecked {
                    ++i;
                }
            }
        }
        if (to == address(0)) {
            for (uint256 i; i < ids.length; ) {
                _resetTokenRoyalty(ids[i]);
                unchecked {
                    ++i;
                }
            }
        }
    }
}
