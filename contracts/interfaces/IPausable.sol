// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

interface IPausable {
    function pause() external;

    function unpause() external;
}
