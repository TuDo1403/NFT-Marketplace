// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

library Tokenizer {
    // TOKEN ID = ADDRESS + TYPE + SUPPLY + METADATA
    uint8 constant TYPE_BIT = 16;
    uint8 constant SUPPLY_BIT = 40;
    uint8 constant METADATA_BIT = 40;
    uint8 constant ADDRESS_BIT = 160;

    uint256 constant METADATA_MASK = (1 << METADATA_BIT) - 1;
    uint256 constant SUPPLY_MASK =
        ((1 << (METADATA_BIT + SUPPLY_BIT)) - 1) ^ METADATA_MASK;
    uint256 constant TYPE_MASK =
        ((1 << (METADATA_BIT + SUPPLY_BIT + TYPE_BIT)) - 1) ^
            (METADATA_MASK | SUPPLY_MASK);

    function createTokenIdFrom(
        uint16 type_,
        uint40 supply_,
        uint40 metadata_,
        address creator_
    ) external pure returns (uint256) {
        uint256 type_padded = uint256(type_);
        uint256 supply_padded = uint256(supply_);
        uint256 metadata_padded = uint256(metadata_);
        uint256 creator_padded = uint256(uint160(creator_));

        uint256 tokenId = metadata_padded |
            (supply_padded << (METADATA_BIT)) |
            (type_padded << (SUPPLY_BIT + METADATA_BIT)) |
            (creator_padded << (TYPE_BIT + SUPPLY_BIT + METADATA_BIT));
        return tokenId;
    }

    function tokenMaxSupply(uint256 id) internal pure returns (uint256) {
        return (id & SUPPLY_MASK) >> METADATA_BIT;
    }

    function tokenType(uint256 id) internal pure returns (uint256) {
        return (id & TYPE_MASK) >> (METADATA_BIT + SUPPLY_BIT);
    }

    function tokenMetaData(uint256 id) internal pure returns (uint256) {
        return uint256(uint40(id));
    }

    function tokenCreator(uint256 id) internal pure returns (address) {
        return address(uint160(id >> (TYPE_BIT + SUPPLY_BIT + METADATA_BIT)));
    }
}
