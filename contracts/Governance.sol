// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IGovernance.sol";

contract Governance is IGovernance, Ownable {
    address public treasury;
    address public verifier;
    address public marketplace;

    mapping(address => bool) public acceptedPayments;

    modifier validAddress(address addr_) {
        if (addr_ == address(0)) {
            revert Governance__InvalidAddress();
        }
        _;
    }

    // 363880
    constructor(
        //address manager_,
        address treasury_,
        address verifier_
    ) validAddress(treasury_) validAddress(verifier_) {
        _transferOwnership(_msgSender());
        treasury = treasury_;
        verifier = verifier_;
    }

    function updateTreasury(address treasury_)
        external
        onlyOwner
        validAddress(treasury_)
    {
        emit TreasuryUpdated(treasury, treasury_);
        treasury = treasury_;
    }

    function updateVerifier(address verifier_)
        external
        onlyOwner
        validAddress(verifier_)
    {
        verifier = verifier_;
    }

    function updateMarketplace(address marketplace_)
        external
        onlyOwner
        validAddress(marketplace_)
    {
        marketplace = marketplace_;
    }

    function registerToken(address token_)
        external
        onlyOwner
        validAddress(token_)
    {
        acceptedPayments[token_] = true;
        emit PaymentUpdated(token_, true);
    }

    function unregisterToken(address token_) external onlyOwner {
        if (!acceptedPayments[token_]) {
            revert Governance__UnregisteredToken();
        }
        delete acceptedPayments[token_];
        emit PaymentUpdated(token_, false);
    }

    function owner()
        public
        view
        override(Ownable, IGovernance)
        returns (address)
    {
        return Ownable.owner();
    }
}
