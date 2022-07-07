// SPDX-License-Identifier: Unlisened
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

interface IGovernance is IAccessControlEnumerable {
    function treasury() external view returns (address);

    function verifier() external view returns (address);

    function manager() external view returns (address);

    function acceptedPayments(address token_) external view returns (bool);
}
