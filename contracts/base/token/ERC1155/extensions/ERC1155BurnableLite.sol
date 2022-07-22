// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "../ERC1155Lite.sol";

abstract contract ERC1155BurnableLite is ERC1155Lite {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external virtual {
        _onlyOwnerOrApproved(account);
        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external virtual {
        _onlyOwnerOrApproved(account);
        _burnBatch(account, ids, values);
    }
}
