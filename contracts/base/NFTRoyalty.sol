// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/token/common/ERC2981.sol";

abstract contract NFTRoyalty is ERC2981 {
    error NFTRoyalty__Unauthorized();

    modifier onlyCreator(address sender_, uint256 tokenId_) {
        _onlyCreator(sender_, tokenId_);
        _;
    }

    function setTokenRoyalty(
        uint256 tokenId_,
        address receiver_,
        uint96 feeNumerator_
    ) external virtual;

    function setDefaultRoyalty(address receiver_, uint96 feeNumerator_)
        external
        virtual;

    function _isCreatorOf(address sender_, uint256 tokenId_)
        internal
        view
        virtual
        returns (bool)
    {
        (address owner_, ) = royaltyInfo(tokenId_, 0);
        return sender_ == owner_;
    }

    function _onlyCreator(address sender_, uint256 tokenId_)
        internal
        view
        virtual
    {
        if (!_isCreatorOf(sender_, tokenId_)) {
            revert NFTRoyalty__Unauthorized();
        }
    }
}
