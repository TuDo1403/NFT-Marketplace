// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.16;

interface IMarketplaceIntegratable {
    error MPI__Unauthorized();
    error MPI__NonZeroAddress();
    error MPI__DelegatecallFailed();

    event GovernanceUpdated(address indexed newAddr);

    function updateGovernance(address addr_) external;
}
