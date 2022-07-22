// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./NFTRoyalty.sol";
import "./MarketplaceIntegratable.sol";

import "./INFTBase.sol";

abstract contract NFTBase is
    INFTBase,
    NFTRoyalty,
    AccessControl,
    MarketplaceIntegratable
{
    uint256 public immutable TYPE;
    //keccak256("MINTER_ROLE")
    bytes32 internal constant MINTER_ROLE =
        0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;

    constructor(uint256 type_) {
        TYPE = type_;
    }

    function _initialize(address admin_, address owner_)
        internal
        virtual
        onlyInitializing
    {
        _initialize(admin_);
        _grantRole(MINTER_ROLE, owner_);
        _grantRole(DEFAULT_ADMIN_ROLE, owner_);
    }

    function setDefaultRoyalty(address receiver_, uint96 feeNumerator_)
        external
        virtual
        override
    {
        _setDefaultRoyalty(receiver_, feeNumerator_);
    }

    function setTokenRoyalty(
        uint256 tokenId_,
        address receiver_,
        uint96 feeNumerator_
    ) external virtual override {
        _onlyCreator(_msgSender(), tokenId_);
        _setTokenRoyalty(tokenId_, receiver_, feeNumerator_);
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
}
