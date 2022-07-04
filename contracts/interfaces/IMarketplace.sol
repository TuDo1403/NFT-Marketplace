// SPDX-License-Identifier: Unlisened
pragma solidity 0.8.15;

interface IMarketplace {
    struct Item {
        uint256 amount;
        uint256 tokenId;
        uint256 unitPrice;
        string tokenURI;
    }

    struct Payment {
        address paymentToken;
        uint256 subTotal;
        uint256 creatorPayout;
        uint256 servicePayout;
        uint256 total;
    }

    struct Receipt {
        address buyer;
        address seller;
        address creator;
        address creatorPayoutAddr;
        Item item;
        Payment payment;
        uint256 deadline;
        uint256 nonce;
    }

    event Received(address caller, uint256 amount, string message);

    function multiDelegatecall(bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results);

    function redeem(
        address seller_,
        address paymentToken_,
        address creatorPayoutAddr_,
        uint256 amount_,
        uint256 tokenId_,
        uint256 deadline_,
        uint256 unitPrice_,
        string calldata tokenURI_,
        bytes calldata signature_
    ) external payable;

    function setName(string calldata name_) external;

    function setSymbol(string calldata symbol_) external;

    function setAdmin(address admin_) external;

    function freezeBaseURI() external;

    function createTokenId(
        uint256 type_,
        uint256 creatorFee_,
        uint256 index_,
        uint256 supply_,
        address creator_
    ) external pure returns (uint256);
}
