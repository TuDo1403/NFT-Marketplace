// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

//import "@openzeppelin/contracts/utils/Strings.sol";
// import "@openzeppelin/contracts/access/IAccessControl.sol";
import "../libraries/ReceiptUtil.sol";
//import "../libraries/TokenIdGenerator.sol";

interface INFT {
    // error NFT__FrozenBase();
    // error NFT__FrozenToken();
    // error NFT__ZeroAddress();
    // error NFT__Unauthorized();

    // event PermanentURI(uint256 indexed tokenId_, string tokenURI_);

    function mint(address to_, ReceiptUtil.Item memory item_) external;

    //function freezeBase() external;

    //function freezeToken(uint256 tokenId_) external;

    //function setBaseURI(string calldata baseURI_) external;

    // function setTokenURI(uint256 tokenId_, string calldata tokenURI_) external;

    // function tokenURI(uint256 tokenId_) external view returns (string memory);

    // function TYPE() external view returns (uint256);
}
