// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

import "../ERC721Lite.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
//import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
//import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "hardhat/console.sol";
import "./IERC721Permit.sol";

/// @title ERC721 with permit
/// @notice Nonfungible tokens that support an approve via signature, i.e. permit
abstract contract ERC721Permit is ERC721Lite, IERC721Permit, EIP712Upgradeable {
    using Counters for Counters.Counter;

    mapping(uint256 => Counters.Counter) public nonces;

    /// @dev Gets the current nonce for a token ID and then increments it, returning the original value

    /// @inheritdoc IERC721Permit
    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /// @dev Value is equal to keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 private constant _PERMIT_TYPEHASH =
        0x49ecf333e5b8c95c40fdafc95c1ad136e8914a8fb55e9dc8bb01eaa83a2df9ad;

    /// @inheritdoc IERC721Permit
    function permit(
        uint256 tokenId_,
        uint256 deadline_,
        address spender_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external override {
        console.log("tokenId: %s", tokenId_);
        console.log("deadline: %s", deadline_);
        console.log("spender: %s", spender_);
        if (block.timestamp > deadline_) {
            revert ERC721Permit__Expired();
        }

        bytes32 digest = ECDSA.toEthSignedMessageHash(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        _PERMIT_TYPEHASH,
                        spender_,
                        tokenId_,
                        _useNonce(tokenId_),
                        deadline_
                    )
                )
            )
        );
        address owner = ownerOf(tokenId_);
        if (spender_ == owner) {
            revert ERC721__SelfApproving();
        }

        if (Address.isContract(owner)) {
            if (
                IERC1271(owner).isValidSignature(
                    digest,
                    abi.encodePacked(r_, s_, v_)
                ) != 0x1626ba7e
            ) {
                revert ERC721__Unauthorized();
            }
        } else {
            address recoveredAddress = ECDSA.recover(digest, v_, r_, s_);
            if (recoveredAddress == address(0)) {
                revert ERC721Permit__InvalidSignature();
            }
            if (recoveredAddress != owner) {
                revert ERC721__Unauthorized();
            }
        }

        _approve(spender_, tokenId_);
    }

    function _useNonce(uint256 tokenId_)
        internal
        virtual
        returns (uint256 nonce)
    {
        nonce = nonces[tokenId_].current();
        nonces[tokenId_].increment();
    }
}
