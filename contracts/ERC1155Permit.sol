// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/draft-ERC1155Permit.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
//import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";

import "./interfaces/IERC1155Permit.sol";

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
    ERC1155,
    IERC1155Permit,
    EIP712,
    Initializable
{
    /// @dev Gets the current nonce for a token ID and then increments it, returning the original value
    function _useNonce(address owner_) internal virtual returns (uint256);

    // /// @dev The hash of the name used in the permit signature verification
    // bytes32 private immutable nameHash;

    // /// @dev The hash of the version string used in the permit signature verification
    // bytes32 private immutable versionHash;

    /// @notice Computes the nameHash and versionHash
    constructor(string memory name_, string memory version_)
        EIP712(name_, version_)
        ERC1155("")
    {}

    /// @inheritdoc IERC1155Permit
    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 nonce,uint256 deadline)"
        );

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
                revert ERC1155Permit__Unauthorized();
            }
        } else {
            address recoveredAddress = ECDSA.recover(digest, v_, r_, s_);
            if (recoveredAddress == address(0)) {
                revert ERC1155Permit__InvalidSignature();
            }
            if (recoveredAddress != owner_) {
                revert ERC1155Permit__Unauthorized();
            }
        }

        _setApprovalForAll(owner_, spender_, true);
    }
}
