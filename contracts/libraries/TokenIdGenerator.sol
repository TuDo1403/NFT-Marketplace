// SPDX-License-Identifier: Unlisened
pragma solidity 0.8.15;

library TokenIdGenerator {
    // TOKEN ID = ADDRESS + TYPE + SUPPLY + FEE + ID
    struct Token {
        uint256 _fee;
        uint256 _type;
        uint256 _supply;
        uint256 _index;
        address _creator;
    }

    uint8 public constant FEE_BIT = 16; // creator fee
    uint8 public constant TYPE_BIT = 16;
    uint8 public constant INDEX_BIT = 32;
    uint8 public constant SUPPLY_BIT = 32; // max supply
    uint8 public constant ADDRESS_BIT = 160;

    uint256 public constant INDEX_MASK = (1 << INDEX_BIT) - 1;
    uint256 public constant FEE_MASK =
        ((1 << (INDEX_BIT + FEE_BIT)) - 1) ^ INDEX_MASK;
    uint256 public constant SUPPLY_MASK =
        ((1 << (INDEX_BIT + FEE_BIT + SUPPLY_BIT)) - 1) ^
            (INDEX_MASK | FEE_MASK);
    uint256 public constant TYPE_MASK =
        ((1 << (INDEX_BIT + FEE_BIT + SUPPLY_BIT + TYPE_BIT)) - 1) ^
            (INDEX_MASK | FEE_MASK | SUPPLY_MASK);

    function createTokenId(Token memory token) internal pure returns (uint256) {
        return
            _createTokenId(
                token._fee,
                token._type,
                token._supply,
                token._index,
                token._creator
            );
    }

    function _createTokenId(
        uint256 fee_,
        uint256 type_,
        uint256 supply_,
        uint256 index_,
        address creator_
    ) private pure returns (uint256) {
        unchecked {
            uint256 creator = uint256(uint160(creator_));
            uint256 tokenId = index_ |
                (fee_ << (INDEX_BIT)) |
                (supply_ << (INDEX_BIT + FEE_BIT)) |
                (type_ << (SUPPLY_BIT + INDEX_BIT + FEE_BIT)) |
                (creator << (TYPE_BIT + SUPPLY_BIT + INDEX_BIT + FEE_BIT));
            return tokenId;
        }
    }

    function getTokenMaxSupply(uint256 id_)
        internal
        pure
        returns (uint256 supply)
    {
        unchecked {
            supply =
                ((id_ & SUPPLY_MASK) >> (INDEX_BIT + FEE_BIT)) %
                (2**SUPPLY_BIT - 1);
        }
    }

    function getTokenType(uint256 id_)
        internal
        pure
        returns (uint256 tokenType)
    {
        unchecked {
            tokenType =
                (id_ & TYPE_MASK) >>
                (INDEX_BIT + FEE_BIT + SUPPLY_BIT) %
                (2**TYPE_BIT - 1);
        }
    }

    function getTokenIndex(uint256 id) internal pure returns (uint256 index) {
        unchecked {
            index = (id & INDEX_MASK) % (2**INDEX_BIT - 1);
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
            fee = ((id_ & FEE_MASK) >> INDEX_BIT) % (2**FEE_BIT - 1);
        }
    }
}
