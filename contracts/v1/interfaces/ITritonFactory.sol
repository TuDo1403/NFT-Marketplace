// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

interface ITritonFactory {
    struct Settings {
        string uri;
        string name;
        string symbol;
    }

    event TokenDeployed(
        uint256 createdTime,
        string uri,
        string name,
        string symbol,
        address indexed deployer,
        address indexed deployedAddress
    );

    function deployCollectible(
        address implement_,
        string calldata uri_,
        string calldata name_,
        string calldata symbol_
    ) external returns (address deployedAddress);

    function getContractOwner(address nftContract) external view returns (address);

    function addStrategy(address nftContract, address nftOwner) external;

    // function deployMultipleCollectibles(
    //     address[] calldata deployers_,
    //     address[] calldata implemetns_,
    //     Settings[] calldata settings_
    // ) external returns (address[] memory deployedAddresses);
}
