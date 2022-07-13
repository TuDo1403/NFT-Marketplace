// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

interface IGovernance is IAccessControlEnumerable {
    function manager() external view returns (address);

    function treasury() external view returns (address);

    function verifier() external view returns (address);

    function marketplace() external view returns (address);

    function acceptedPayments(address token_) external view returns (bool);
}
