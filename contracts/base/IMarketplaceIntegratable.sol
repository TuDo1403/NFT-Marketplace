// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

//import "@openzeppelin/contracts/";

interface IMarketplaceIntegratable {
    error MPI__Unauthorized();
    error MPI__NonZeroAddress();

    event GovernanceUpdated(address indexed newAddr);

    function updateGovernance(address addr_) external;
}
