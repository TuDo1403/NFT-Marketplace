// SPDX-License-Identifier: Unlisened
pragma solidity 0.8.15;

interface IMPIntegratable {
    function initialize(
        address creator_,
        address payout,
        string calldata uri_,
        string calldata name_,
        string calldata symbol_
    ) external;
}
