// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import "../ERC1155Lite.sol";

import "../../../../libraries/TokenIdGenerator.sol";

abstract contract ERC1155SupplyLite is ERC1155Lite {
    using TokenIdGenerator for uint256;

    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155SupplyLite.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        uint256 length = ids.length;
        uint256 tokenId;
        uint256 amount;
        if (from == address(0)) {
            // uint256 MAX_SUPPLY;
            // unchecked {
            //     MAX_SUPPLY = 2**TokenIdGenerator.SUPPLY_BIT - 1;
            // }
            uint256 maxSupply;
            for (uint256 i; i < length; ) {
                tokenId = ids[i];
                amount = amounts[i];
                //_supplyCheck(tokenId, amount);
                if (amount > TokenIdGenerator.SUPPLY_MAX) {
                    revert ERC1155__AllocationExceeds();
                }
                maxSupply = tokenId.getTokenMaxSupply();
                if (maxSupply != 0) {
                    unchecked {
                        if (amount + totalSupply(tokenId) > maxSupply) {
                            revert ERC1155__AllocationExceeds();
                        }
                    }
                }
                unchecked {
                    _totalSupply[tokenId] += amount;
                    ++i;
                }
            }
        }
        uint256 supply;
        if (to == address(0)) {
            for (uint256 i; i < length; ) {
                tokenId = ids[i];
                amount = amounts[i];
                supply = _totalSupply[tokenId];
                if (supply < amount) {
                    revert ERC1155__AllocationExceeds();
                }
                unchecked {
                    _totalSupply[tokenId] = supply - amount;
                    ++i;
                }
            }
        }
    }
}
