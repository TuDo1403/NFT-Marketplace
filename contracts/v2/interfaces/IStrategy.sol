// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {OrderTypes} from "../libraries/OrderTypes.sol";

interface IStrategy {
    function canExecuteTakerAsk(
        OrderTypes.TakerOrder calldata takerAsk,
        OrderTypes.MakerOrder calldata makerBid
    )
        external
        returns (
            bool,
            uint256,
            uint256
        );

    function canExecuteTakerBid(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    )
        external
        returns (
            bool,
            uint256,
            uint256
        );

    function viewProtocolFee() external view returns (uint256);
}
