// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.16;

library TokenIdGenerator {
    // TOKEN ID = ADDRESS + SUPPLY + TYPE + FEE + ID

    uint256 public constant FEE_BIT = 16;
    uint256 public constant TYPE_BIT = 16;
    uint256 public constant INDEX_BIT = 32;
    uint256 public constant SUPPLY_BIT = 32;
    uint256 public constant ADDRESS_BIT = 160;

    uint256 public constant FEE_MAX = ~uint16(0);
    uint256 public constant TYPE_MAX = ~uint16(0);
    uint256 public constant INDEX_MAX = ~uint32(0);
    uint256 public constant SUPPLY_MAX = ~uint32(0);

    uint256 private constant INDEX_MASK = (1 << INDEX_BIT) - 1;
    uint256 private constant FEE_MASK =
        ((1 << (INDEX_BIT + FEE_BIT)) - 1) ^ INDEX_MASK;
    uint256 private constant TYPE_MASK =
        ((1 << (INDEX_BIT + FEE_BIT + TYPE_BIT)) - 1) ^ (INDEX_MASK | FEE_MASK);
    uint256 private constant SUPPLY_MASK =
        ((1 << (INDEX_BIT + FEE_BIT + TYPE_BIT + SUPPLY_BIT)) - 1) ^
            (INDEX_MASK | FEE_MASK | TYPE_MASK);

    function createTokenId(
        uint256 fee_,
        uint256 type_,
        uint256 supply_,
        uint256 index_,
        address creator_
    ) internal pure returns (uint256) {
        unchecked {
            return
                index_ |
                (fee_ << (INDEX_BIT)) |
                (type_ << (INDEX_BIT + FEE_BIT)) |
                (supply_ << (INDEX_BIT + FEE_BIT + TYPE_BIT)) |
                (uint256(uint160(creator_)) <<
                    (INDEX_BIT + FEE_BIT + TYPE_BIT + SUPPLY_BIT));
        }
    }

    function getTokenMaxSupply(uint256 id_)
        internal
        pure
        returns (uint256 supply)
    {
        unchecked {
            supply =
                ((id_ & SUPPLY_MASK) >> (INDEX_BIT + FEE_BIT + TYPE_BIT)) %
                SUPPLY_MAX;
        }
    }

    function getTokenType(uint256 id_)
        internal
        pure
        returns (uint256 tokenType)
    {
        unchecked {
            tokenType = ((id_ & TYPE_MASK) >> (INDEX_BIT + FEE_BIT)) % TYPE_MAX;
        }
    }

    function getTokenIndex(uint256 id) internal pure returns (uint256 index) {
        unchecked {
            index = (id & INDEX_MASK) % INDEX_MAX;
        }
    }

    function getTokenCreator(uint256 id_) internal pure returns (address addr) {
        unchecked {
            addr = address(
                uint160(id_ >> (TYPE_BIT + SUPPLY_BIT + INDEX_BIT + FEE_BIT))
            );
        }
    }

    function getCreatorFee(uint256 id_) internal pure returns (uint256 fee) {
        unchecked {
            fee = ((id_ & FEE_MASK) >> INDEX_BIT) % FEE_MAX;
        }
    }
}
