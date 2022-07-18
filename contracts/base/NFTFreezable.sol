// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

import "./INFTFreezable.sol";

abstract contract NFTFreezable is INFTFreezable {
    bool public isFrozenBase;

    mapping(uint256 => bool) public frozenTokens;

    modifier notFrozenBase() {
        if (isFrozenBase) {
            revert NFTFreezable__FrozenBase();
        }
        _;
    }

    modifier notFrozenToken(uint256 tokenId_) {
        _notFrozenToken(tokenId_);
        _;
    }

    function setBaseURI(string calldata baseURI_) external virtual override;

    function freezeBaseURI() external virtual override notFrozenBase {
        _freezeBaseURI();
    }

    // function setTokenURI(uint256 tokenId_, string calldata tokenURI_)
    //     external
    //     notFrozenToken(tokenId_)
    // {
    //     _onlyCreatorOrHasRole(_msgSender(), tokenId_, URI_SETTER_ROLE);
    //     _setURI(tokenId_, tokenURI_);
    //     _freezeToken(tokenId_);
    // }

    function freezeToken(uint256 tokenId_) external virtual override {
        _freezeToken(tokenId_);
    }

    function _freezeBaseURI() internal virtual {
        isFrozenBase = true;
    }

    function _freezeToken(uint256 tokenId_) internal virtual {
        frozenTokens[tokenId_] = true;
    }

    function _notFrozenToken(uint256 tokenId_) internal view {
        if (frozenTokens[tokenId_]) {
            revert NFTFreezable__FrozenToken();
        }
    }
}
