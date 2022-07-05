// SPDX-License-Identifier: Unlisened
pragma solidity ^0.8.15;

import "./interfaces/ICollectible.sol";

/// @title Abstract contract for NFT
/// @author Dat Nguyen (datndt@inspirelab.io)

contract Collectible is ICollectible {
    // State variables
    address private factory;

    /**
     * @notice Initialize for Collectible contract
     * @param _admin NFT Contract owner
     * @param _uri URI of NFT
     * @param _name Name of NFT
     * @param _symbol Symboy of NFT
     */
    function initialize(
        address _admin,
        string calldata _uri,
        string calldata _name,
        string calldata _symbol
    ) external virtual {}

    /**
     * @notice Get type of Collectible
     * @return Type of NFT (uint96)
     */
    function getType() external virtual returns (uint96) {}

    /**
     * @notice Set the token URI
     * @param tokenId Token ID need to set URI
     * @param uri New URI token
     */
    function setTokenURI(uint256 tokenId, bytes memory uri) external virtual {}

    /**
     * @notice Freeze token URI
     * @param tokenId Token ID need to freeze URI
     */
    function freezeTokenURI(uint256 tokenId) external virtual {}
}
