// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

interface IGovernance {
    error Governance__Unauthorized();
    error Governance__InvalidAddress();
    error Governance__UnregisteredToken();

    event PaymentUpdated(address indexed token_, bool registed);
    event TreasuryUpdated(address indexed from_, address indexed to_);

    function owner() external view returns (address);

    function treasury() external view returns (address);

    function verifier() external view returns (address);

    function marketplace() external view returns (address);

    function acceptedPayments(address token_) external view returns (bool);
}
