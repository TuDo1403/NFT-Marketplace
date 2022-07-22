// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Lite is IERC721 {
    error ERC721__NonZeroAddress();
    error ERC721__Unauthorized();
    error ERC721__TokenExisted();
    error ERC721__InvalidInput();
    error ERC721__SelfApproving();
    error ERC721__TokenUnexisted();
    error ERC721__ERC721ReceiverNotImplemented();
}
