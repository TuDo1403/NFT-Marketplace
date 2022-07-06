// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

interface INFTFactory {
    error Unauthorized();
    error InvalidAddress();
    error DelegatecallFailed();
    struct Settings {
        string uri;
        string name;
        string symbol;
    }

    event TokenDeployed(
        string uri,
        string name,
        string symbol,
        string indexed standard,
        address indexed deployer,
        address indexed deployedAddress
    );

    function deployCollectible(
        address implement_,
        string calldata uri_,
        string calldata name_,
        string calldata symbol_
    ) external returns (address deployedAddress);

    function multiDelegatecall(bytes[] calldata data)
        external
        returns (bytes[] memory);
}
