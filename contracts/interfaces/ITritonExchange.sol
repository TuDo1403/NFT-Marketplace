// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

interface IMarketplace {
    event ItemListed(
        address owner,
        uint256 price,
        uint256 listedTime,
        uint256 indexed itemId,
        uint256 indexed tokenId,
        address indexed nftContract
    );
    event ItemUnListed(
        address owner,
        uint256 price,
        uint256 unListedTime,
        uint256 indexed itemId,
        uint256 indexed tokenId,
        address indexed nftContract
    );
    event ItemSold(
        uint256 price,
        uint256 payout,
        address oldOwner,
        address newOwner,
        uint256 tradedTime,
        uint256 indexed itemId,
        uint256 indexed tokenId,
        address indexed nftContract
    );
    event PriceChanged(
        uint256 oldPrice,
        uint256 newPrice,
        uint256 priceChangedTime,
        uint256 indexed itemId,
        uint256 indexed tokenId,
        address indexed nftContract
    );

    function listItem(address nftContract, uint256 itemId, uint256 price) external;

    function unListItem(uint256 itemId) external;

    function buyNft(address nftContract, uint256 itemId) external payable;

    function changeItemPrice(uint256 itemId, uint256 newPrice) external;
}
