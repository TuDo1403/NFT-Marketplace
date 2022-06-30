// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

import "./interfaces/ITritonExchange.sol";
import "./interfaces/ICollectible.sol";
import "./interfaces/ITritonFactory.sol";

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/// @custom:security-contact datndt@inspirelab.io
contract TritonMarketplace is ITritonMarketplace, Context
{
    // State variables
    address payable private marketOwner;

    uint256 public marketItemCounter;
    uint256 public soldItemCounter;

    ITritonFactory tritonFactory;


    struct MarketItem {
        address nftContract;
        uint256 tokenId;
        string ercType;
        address payable owner;
        address payable buyer;
        uint256 price;
        uint256 listedTime;
        bool listed;
        bool sold;
    }

    mapping(uint256 => MarketItem) public marketItems;

    constructor(
        address _factory
    ) {
        marketItemCounter = 0;
        soldItemCounter = 0;

        marketOwner = payable(msg.sender);

        tritonFactory = ITritonFactory(_factory);
    }

    // Functional
    function listItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external override {
        // Check nft contract is strategy
        require(tritonFactory.getContractOwner(nftContract) != address(0), "Marketplace: NFT Contract must be strategy!");
        // Check price > 0
        require(price > 0, "Marketplace: Price must be greater than 0!");
        // Check nft approval to marketplace
        IERC721Upgradeable nft = IERC721Upgradeable(nftContract);
        if (nft.getApproved(tokenId) != address(this)) {
            nft.approve(address(this), tokenId);
        }

        marketItems[marketItemCounter] = MarketItem(
            nftContract,
            tokenId,
            "1155",
            payable(msg.sender),
            payable(address(0)),
            price,
            block.timestamp,
            true,
            false
        );

        marketItemCounter += 1;

        emit ItemListed(
            _msgSender(),
            price,
            block.timestamp,
            marketItemCounter,
            tokenId,
            nftContract
        );
    }

    function unListItem(uint256 itemId) external override {
        // Check nft owner
        require(marketItems[itemId].owner == msg.sender, "Marketplace: This NFT doesnt belong to you!");

        marketItems[itemId].listed = false;

        emit ItemUnListed(
            msg.sender, 
            marketItems[itemId].price, 
            block.timestamp, 
            itemId, 
            marketItems[itemId].tokenId, 
            marketItems[itemId].nftContract
            );
    }

    function buyNft(address nftContract, uint256 itemId) external payable override {
        // Check enough money to buy nft
        require(marketItems[itemId].price >= msg.value, "Marketplace: Not enough money to buy this NFT!");

        // Transaction fee
        marketOwner.transfer(msg.value * 25 / 1000);
        address seller = marketItems[itemId].owner;

        // Send money to seller
        payable(seller).transfer(msg.value * 975 / 1000);

        // Send NFT to buyer
        IERC721(nftContract).transferFrom(payable(seller), payable(msg.sender), marketItems[itemId].tokenId);

        // Change state when nft had sold 
        marketItems[itemId].buyer = payable(msg.sender);
        marketItems[itemId].sold = true;
        marketItems[itemId].listed = false;

        soldItemCounter += 1;

        emit ItemSold(
            marketItems[itemId].price,
            marketItems[itemId].price,
            seller,
            msg.sender,
            block.timestamp,
            itemId,
            marketItems[itemId].tokenId,
            nftContract
        );
    }

    function changeItemPrice(uint256 itemId, uint256 newPrice) external override {
        // Check nft owner
        require(marketItems[itemId].owner == msg.sender, "Marketplace: This NFT isn't belong to you!");

        uint256 oldPrice = marketItems[itemId].price;
        marketItems[itemId].price = newPrice;

        emit PriceChanged(
            oldPrice, 
            newPrice, 
            block.timestamp,
            itemId,
            marketItems[itemId].tokenId, 
            marketItems[itemId].nftContract
        );
    }
}