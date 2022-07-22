// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IERC1155Lite is IERC1155 {
    error ERC1155__ZeroAddress();
    error ERC1155__Unauthorized();
    error ERC1155__TokenExisted();
    error ERC1155__TokenRejected();
    error ERC1155__SelfApproving();
    error ERC1155__LengthMismatch();
    error ERC1155__TokenUnexisted();
    error ERC1155__AllocationExceeds();
    error ERC1155__InsufficientBalance();
    error ERC1155__ERC1155ReceiverNotImplemented();
}
