// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

import "./ICollectible.sol";
import "./IERC1155Permit.sol";

interface ICollectible1155 is ICollectible {
    error ERC1155__Unauthorized();
    error ERC1155__TokenExisted();
    error ERC1155__StringTooLong();
    error ERC1155__LengthMismatch();
    error ERC1155__AllocationExceeds();

    function mint(uint256 tokenId_, uint256 amount_) external;

    function mintBatch(
        uint256[] calldata tokenIds_,
        uint256[] calldata amounts_
    ) external;

    function mintBatch(address to_, ReceiptUtil.Bulk memory bulk_) external;

    // function transferBatch(
    //     address from_,
    //     address to_,
    //     uint256[] memory amounts_,
    //     uint256[] memory tokenId_
    // ) external;
}
