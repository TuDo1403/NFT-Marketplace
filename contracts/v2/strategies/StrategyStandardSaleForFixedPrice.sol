// SPDX-License-Identitier: UNLICENSED
pragma solidity ^0.8.15;

import "../interfaces/IStrategy.sol";

contract StrategyStandardSaleForFixedPrice is IStrategy {
    // State variables
    uint256 immutable PROTOCOL_FEE;

    constructor(uint256 _protocolFee) {
        PROTOCOL_FEE = _protocolFee;
    }

    function canExecuteTakerAsk(
        OrderTypes.TakerOrder calldata takerAsk,
        OrderTypes.MakerOrder calldata makerBid
    )
        external
        override
        returns (
            bool,
            uint256,
            uint256
        )
    {
        return (
            ((makerBid.price == takerAsk.price) &&
                (makerBid.tokenId == takerAsk.tokenId) &&
                (makerBid.startTime <= block.timestamp) &&
                (makerBid.endTime >= block.timestamp)),
            makerBid.tokenId,
            makerBid.amount
        );
    }

    function canExcuteTakerBid(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    )
        external
        override
        returns (
            bool,
            uint256,
            uint256
        )
    {
        return (
            ((makerAsk.price == takerBid.price) &&
                (makerAsk.tokenId == takerBid.tokenId) &&
                (makerAsk.startTime <= block.timestamp) &&
                (makerAsk.endTime >= block.timestamp)),
            makerAsk.tokenId,
            makerAsk.amount
        );
    }

    function viewProtocolFee() external view override returns (uint256)  {
        return PROTOCOL_FEE;
    }
}
