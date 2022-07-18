// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

interface INFTFactory {
    error Factory__Unauthorized();
    error Factory__InvalidAddress();
    error Factory__ExecutionFailed();

    event TokenDeployed(
        string name_,
        string symbol_,
        string baseURI_,
        uint256 indexed standard_,
        address indexed deployer_,
        address indexed deployedAddr_
    );

    function setGovernance(address governance_) external;

    function multiDelegatecall(bytes[] calldata data)
        external
        returns (bytes[] memory);

    function deployCollectible(
        string calldata name_,
        string calldata symbol_,
        string calldata baseURI_
    ) external returns (address clone);
}
