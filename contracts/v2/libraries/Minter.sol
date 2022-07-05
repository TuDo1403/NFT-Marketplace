//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

library OrderTypes {
    // keccak256("Minter(address signer,address nftAddress,uint256 tokenId,bytes params,uint8 v,bytes32 r,bytes32 s)"")
    bytes32 internal constant MINTER_HASH = 0x81dcefc4878ca4f3ac3dda055dcbe378dd98b2bec30476a67987f02ec4593bb8;

    struct Minter {
        address signer;
        address nftAddress;
        uint256 tokenId;
        bytes params;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function hash(Minter memory minter) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                minter.signer,
                minter.nftAddress,
                minter.tokenId,
                keccak256(minter.params)
            )   
        );
    }
}