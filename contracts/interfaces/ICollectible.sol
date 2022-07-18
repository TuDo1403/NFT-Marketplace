// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "../libraries/TokenIdGenerator.sol";
import "../libraries/ReceiptUtil.sol";

interface ICollectible is IAccessControl {
    error NFT__FrozenBase();
    error NFT__FrozenToken();
    error NFT__TokenExisted();
    error NFT__Unauthorized();
    error NFT__InvalidInput();
    error NFT__StringTooLong();

    event PermanentURI(uint256 indexed tokenId_, string tokenURI_);

    function mint(address to_, ReceiptUtil.Item memory item_) external;

    function freezeBase() external;

    function freezeToken(uint256 tokenId_) external;

    function setBaseURI(string calldata baseURI_) external;

    // function transferSingle(
    //     address from_,
    //     address to_,
    //     uint256 amount_,
    //     uint256 tokenId_
    // ) external;

    // function isMintedBefore(
    //     address seller_,
    //     uint256 tokenId_,
    //     uint256 amount_
    // ) external view returns (bool);

    function setTokenURI(uint256 tokenId_, string calldata tokenURI_) external;

    function tokenURI(uint256 tokenId_) external view returns (string memory);

    function TYPE() external view returns (uint256);
}
