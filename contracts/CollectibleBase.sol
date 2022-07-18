// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "./interfaces/IGovernance.sol";
import "./interfaces/ICollectible.sol";

abstract contract CollectibleBase is AccessControl, ICollectible, ERC2981 {
    using TokenIdGenerator for uint256;

    bool public isFrozenBase;

    IGovernance public immutable admin;

    string public constant VERSION = "1";

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");

    mapping(uint256 => bool) public frozenTokens;

    modifier notFrozenBase() {
        if (isFrozenBase) {
            revert NFT__FrozenBase();
        }
        _;
    }

    modifier onlyMarketplace() {
        if (_msgSender() != admin.marketplace()) {
            revert NFT__Unauthorized();
        }
        _;
    }

    modifier onlyCreatorAndNotFrozen(uint256 tokenId_) {
        _onlyCreatorAndNotFrozen(_msgSender(), tokenId_);
        _;
    }

    constructor(address admin_) {
        admin = IGovernance(admin_);
    }

    function setTokenRoyalty(
        uint256 tokenId_,
        address receiver_,
        uint256 feeNumerator_
    ) external onlyCreatorAndNotFrozen(tokenId_) {
        _setTokenRoyalty(tokenId_, receiver_, uint96(feeNumerator_));
    }

    function freezeToken(uint256 tokenId_)
        external
        override
        onlyCreatorAndNotFrozen(tokenId_)
    {
        _freezeToken(tokenId_);
    }

    function setBaseURI(string calldata baseURI_) external virtual override;

    function freezeBase()
        external
        override
        onlyRole(URI_SETTER_ROLE)
        notFrozenBase
    {
        _freezeBase();
    }

    function _freezeBase() internal virtual;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, AccessControl)
        returns (bool)
    {
        return
            type(ICollectible).interfaceId == interfaceId ||
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    function _freezeToken(uint256 tokenId_) internal virtual {
        frozenTokens[tokenId_] = true;
    }

    function _onlyCreatorAndNotFrozen(address sender_, uint256 tokenId_)
        internal
        view
    {
        if (sender_ != tokenId_.getTokenCreator()) {
            revert NFT__Unauthorized();
        }
        if (frozenTokens[tokenId_]) {
            revert NFT__FrozenToken();
        }
    }

    // function _onlyMarketplace() internal view {
    //     if (_msgSender() != admin.marketplace()) {
    //         revert NFT__Unauthorized();
    //     }
    // }
}
