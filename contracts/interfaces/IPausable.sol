// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

interface IPausable {
    function pause() external;

    function unpause() external;
}
