// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

import "@openzeppelin/contracts/utils/Context.sol";

import "./IMarketplaceIntegratable.sol";

import "../interfaces/IGovernance.sol";

abstract contract MarketplaceIntegratable is IMarketplaceIntegratable {
    IGovernance public admin;

    modifier onlyManager(address sender_) {
        if (sender_ != admin.manager()) {
            revert MPI__Unauthorized();
        }
        _;
    }

    constructor(address admin_) {
        admin = IGovernance(admin_);
    }

    function updateGovernance(address addr_)
        external
        virtual
        override
    {
        if (addr_ == address(0)) {
            revert MPI__NonZeroAddress();
        }
        admin = IGovernance(addr_);

        emit GovernanceUpdated(addr_);
    }
}
