//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

library OrderTypes {
    // keccak256("MakerOrder(bool isOrderAsk,address signer,address nftAddress,uint256 tokenId,uint256 price,uint256 amount,uint256 nonce,address strategy, uint256 startTime,uint256 endTime,uint256 minPercentageToAsk,bytes params)")
    bytes32 internal constant MAKER_ORDER_HASH = 0x8293da783364d7ae9695e98de06d375d47a7a75fedb103e209c0f6f332e7282d;

    struct MakerOrder {
        bool isOrderAsk; // true: Ask, false: Bid
        address signer;
        address nftAddress;
        uint256 tokenId;
        address currency;
        uint256 price;
        uint256 amount; // for ERC1155
        uint256 nonce; // unique for each order
        address strategy;
        uint256 startTime;
        uint256 endTime;
        uint256 minPercentageToAsk;
        bytes params;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct TakerOrder {
        bool isOrderAsk;
        uint256 tokenId;
        address taker;
        uint256 price;
        bytes params;
    }

    function hash(MakerOrder memory makerOrder)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                MAKER_ORDER_HASH,
                makerOrder.isOrderAsk,
                makerOrder.signer,
                makerOrder.nftAddress,
                makerOrder.tokenId,
                makerOrder.price,
                makerOrder.amount,
                makerOrder.nonce,
                makerOrder.startTime,
                makerOrder.endTime,
                makerOrder.minPercentageToAsk,
                keccak256(makerOrder.params)
            )
        );
    }
}
