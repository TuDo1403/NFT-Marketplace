// SPDX-License-Identifier: Unlisened
pragma solidity 0.8.15;

import "./IMarketplace.sol";

interface ICollectible is IMarketplace {
    event ItemSold(
        uint256 price,
        uint256 payout,
        address from,
        address to,
        uint256 indexed id
    );
    event PriceChanged(uint256 newPrice, uint256 indexed id);

    event TokenMinted(uint256 id, address owner);

    function initialize(
        address owner_,
        string calldata name_,
        string calldata symbol_,
        string calldata baseURI_
    ) external;

    function setBaseURI(string calldata baseURI_) external;

    function setTokenURI(uint256 tokenId_, string calldata tokenURI_) external;

    function mint(uint256 tokenId_, uint256 amount_) external;

    function mint(
        uint256 type_,
        uint256 creatorFee_,
        uint256 index_,
        uint256 supply_,
        uint256 amount_,
        string calldata tokenURI_
    ) external;

    function getTokenURI(uint256 tokenId_)
        external
        view
        returns (string memory);

    function getType() external pure returns (string memory);
}
