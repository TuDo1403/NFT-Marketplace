// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./NFTRoyalty.sol";
import "./NFTFreezable.sol";
import "./MarketplaceIntegratable.sol";

import "./INFTBase.sol";

abstract contract NFTBase is
    INFTBase,
    NFTRoyalty,
    AccessControl,
    MarketplaceIntegratable
{
    uint256 public immutable TYPE;

    // keccak256("MINTER_ROLE")
    bytes32 public constant MINTER_ROLE =
        0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;

    string public constant VERSION = "v1";

    modifier onlyMarketplaceOrMinter() {
        address sender = _msgSender();
        if (sender != admin.marketplace()) {
            _checkRole(MINTER_ROLE, sender);
        }
        _;
    }

    constructor(
        address admin_,
        address owner_,
        uint256 type_
    ) MarketplaceIntegratable(admin_) {
        TYPE = type_;

        _grantRole(MINTER_ROLE, owner_);
        _grantRole(DEFAULT_ADMIN_ROLE, owner_);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver_, uint96 feeNumerator_)
        external
        virtual
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver_, feeNumerator_);
    }

    function setTokenRoyalty(
        uint256 tokenId_,
        address receiver_,
        uint96 feeNumerator_
    ) external virtual override onlyCreator(_msgSender(), tokenId_) {
        _setTokenRoyalty(tokenId_, receiver_, feeNumerator_);
    }
}
