// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IMarketplaceIntegratable.sol";
import "../interfaces/IGovernance.sol";

abstract contract MarketplaceIntegratable is
    Initializable,
    IMarketplaceIntegratable
{
    IGovernance public admin;

    // function kill() external payable {
    //     if (msg.sender != admin.owner()) {
    //         (bool success, ) = payable(admin.treasury()).call{value: msg.value}(
    //             ""
    //         );
    //         assert(success);
    //     } else {
    //         selfdestruct(payable(admin.treasury()));
    //     }
    // }

    function _initialize(address admin_) internal onlyInitializing {
        __nonZeroAddress(admin_);
        admin = IGovernance(admin_);
    }

    function __nonZeroAddress(address addr_) private pure {
        if (addr_ == address(0)) {
            revert MPI__NonZeroAddress();
        }
    }

    function _onlyManager() internal view {
        if (msg.sender != admin.owner()) {
            revert MPI__Unauthorized();
        }
    }

    function updateGovernance(address addr_) external override {
        _onlyManager();
        __nonZeroAddress(addr_);
        admin = IGovernance(addr_);
        emit GovernanceUpdated(addr_);
    }
}
