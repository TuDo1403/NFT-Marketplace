// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "./ITokenFreezable.sol";

abstract contract TokenFreezable is ITokenFreezable {
    bool public isFrozenBase;

    mapping(uint256 => bool) public frozenTokens;

    modifier notFrozenBase() {
        if (isFrozenBase) {
            revert TokenFreezable__FrozenBase();
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
            revert TokenFreezable__FrozenToken();
        }
    }
}
