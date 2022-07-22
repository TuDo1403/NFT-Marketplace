// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/draft-ERC1155Permit.sol)

pragma solidity ^0.8.13;

//import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
//import "./external/contracts/proxy/utils/Initializable.sol";

import "../ERC1155Lite.sol";
//import "./external/contracts/token/ERC1155/ERC1155.sol";
//import "./external/contracts/utils/cryptography/draft-EIP712.sol";
// import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
//import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
//import "./external/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";

import "./IERC1155Permit.sol";

/**
 * @dev Implementation of the ERC1155 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC1155 allowance (see {IERC1155-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC1155-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC1155Permit is
    ERC1155Lite,
    IERC1155Permit,
    EIP712Upgradeable
{
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) public nonces;

    // /// @dev The hash of the name used in the permit signature verification
    // bytes32 private immutable nameHash;

    // /// @dev The hash of the version string used in the permit signature verification
    // bytes32 private immutable versionHash;

    /// @notice Computes the nameHash and versionHash

    /// @inheritdoc IERC1155Permit
    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    //keccak256("Permit(address owner,address spender,uint256 nonce,uint256 deadline)");
    bytes32 private constant _PERMIT_TYPEHASH =
        0xdaab21af31ece73a508939fedd476a5ee5129a5ed4bb091f3236ffb45394df62;

    /// @inheritdoc IERC1155Permit
    function permit(
        uint256 deadline_,
        address owner_,
        address spender_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external override {
        if (block.timestamp > deadline_) {
            revert ERC1155Permit__Expired();
        }

        bytes32 digest = ECDSA.toEthSignedMessageHash(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        _PERMIT_TYPEHASH,
                        owner_,
                        spender_,
                        _useNonce(owner_),
                        deadline_
                    )
                )
            )
        );

        if (Address.isContract(owner_)) {
            if (
                IERC1271(owner_).isValidSignature(
                    digest,
                    abi.encodePacked(r_, s_, v_)
                ) != 0x1626ba7e
            ) {
                revert ERC1155__Unauthorized();
            }
        } else {
            address recoveredAddress = ECDSA.recover(digest, v_, r_, s_);
            if (recoveredAddress == address(0)) {
                revert ERC1155Permit__InvalidSignature();
            }
            if (recoveredAddress != owner_) {
                revert ERC1155__Unauthorized();
            }
        }

        _setApprovalForAll(owner_, spender_, true);
    }

    /// @dev Gets the current nonce for a token ID and then increments it, returning the original value
    function _useNonce(address owner_)
        internal
        virtual
        returns (uint256 nonce)
    {
        nonce = nonces[owner_].current();
        nonces[owner_].increment();
    }
}
