// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.16;

interface IPausable {
    function pause() external;

    function unpause() external;
}
