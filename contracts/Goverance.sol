// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

import "./interfaces/IGovernance.sol";

contract Governance is IGovernance {
    function hasRole(bytes32 role, address account)
        external
        view
        override
        returns (bool)
    {}

    function getRoleAdmin(bytes32 role)
        external
        view
        override
        returns (bytes32)
    {}

    function grantRole(bytes32 role, address account) external override {}

    function revokeRole(bytes32 role, address account) external override {}

    function renounceRole(bytes32 role, address account) external override {}

    function getRoleMember(bytes32 role, uint256 index)
        external
        view
        override
        returns (address)
    {}

    function getRoleMemberCount(bytes32 role)
        external
        view
        override
        returns (uint256)
    {}

    function treasury() external view override returns (address) {}

    function verifier() external view override returns (address) {}

    function manager() external view override returns (address) {}

    function acceptPayment(address token_)
        external
        view
        override
        returns (bool)
    {}
}
