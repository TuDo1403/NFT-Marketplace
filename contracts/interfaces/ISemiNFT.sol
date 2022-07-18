// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

//import "./IERC1155Permit.sol";
import "./INFT.sol";
import "../libraries/ReceiptUtil.sol";

interface ISemiNFT is INFT {
    function mint(uint256 tokenId_, uint256 amount_) external;

    function mint(address to_, ReceiptUtil.Item memory item_) external;

    function mintBatch(
        uint256[] calldata tokenIds_,
        uint256[] calldata amounts_
    ) external;

    function mintBatch(address to_, ReceiptUtil.Bulk memory bulk_) external;
}
