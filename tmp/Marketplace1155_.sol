// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

import "./interfaces/IMarketplace.sol";
import "./interfaces/ICollectible.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/// @custom:security-contact tudm@inspirelab.io
contract Marketplace1155 is
    IMarketplace,
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant VERSION = keccak256("Marketplacev1");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    mapping(uint256 => Item) public items;

    modifier onlyOwner(uint256 id) {
        Item memory item = items[id];
        require(
            IERC1155(item.nftContract).balanceOf(_msgSender(), item.tokenId) !=
                0,
            "Marketplace: Only owner"
        );
        _;
    }

    modifier onlyListing(uint256 id) {
        require(items[id].isListing, "Marketplace: Item not listed");
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    function kill() external onlyRole(DEFAULT_ADMIN_ROLE) {
        selfdestruct(payable(_msgSender()));
    }

    function initialize(address admin) external initializer {
        __Pausable_init();

        __AccessControl_init();
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function multiDelegateCall(bytes[] calldata data)
        external
        payable
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bytes[] memory results)
    {
        results = new bytes[](data.length);
        for (uint256 i; i < data.length; ) {
            (bool ok, bytes memory _result) = address(this).delegatecall(
                data[i]
            );
            if (!ok) {
                revert DelegateCallFailed(data[i]);
            }
            results[i] = _result;
            unchecked {
                ++i;
            }
        }
    }

    function listItem(
        uint256 price,
        uint256 tokenId,
        address nftContract
    ) external override {
        uint256 id = computeItemId(tokenId, nftContract);
        Item memory item = items[id];

        require(
            !item.isListing && item.price == 0,
            "Marketplace: Item already listed"
        );

        if (item.price != 0) {
            _changeItemPrice(id, price);
            items[id].isListing = true;
        } else {
            item = Item({
                price: price,
                isListing: true,
                tokenId: tokenId,
                nftContract: nftContract
            });
            items[id] = item;
            emit ItemListed(_msgSender(), id, tokenId, nftContract);
        }
    }

    function unListItem(uint256 id)
        external
        override
        onlyOwner(id)
        onlyListing(id)
    {
        require(items[id].isListing, "Marketplace: Item not listed");
        items[id].isListing = false;
        emit ItemUnListed(id);
    }

    function buyNft(uint256 id) external payable override onlyListing(id) {
        require(
            msg.value >= items[id].price,
            "Marketplace: Insufficient payment"
        );

        address buyer = _msgSender();
    }

    function changeItemPrice(uint256 id, uint256 newPrice) external override {
        _changeItemPrice(id, newPrice);
    }

    function _changeItemPrice(uint256 id, uint256 newPrice)
        internal
        onlyOwner(id)
    {
        Item memory item = items[id];
        require(
            newPrice > 0 && newPrice < item.price,
            "Marketplace: Only discount"
        );
        items[id].price = newPrice;
        emit PriceChanged({id: id, newPrice: newPrice});
    }

    function computeItemId(uint256 tokenId, address nftContract)
        internal
        pure
        returns (uint256)
    {
        return
            uint256(keccak256(abi.encodePacked(VERSION, tokenId, nftContract)));
    }
}
