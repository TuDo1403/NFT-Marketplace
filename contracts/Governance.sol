// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.13;

contract Governance {
    error Unauthorized();
    error InvalidAddress();
    error UnregisteredToken();

    address public treasury;
    address public verifier;
    address public manager;

    mapping(address => bool) public acceptedPayments;

    event TreasuryUpdated(address indexed from_, address indexed to_);
    event PaymentUpdated(address indexed token_, bool registed);

    modifier onlyOwner() {
        if (msg.sender != manager) {
            revert Unauthorized();
        }
        _;
    }
    // 363880
    constructor(address treasury_, address verifier_, address manager_) {
        treasury = treasury_;
        verifier = verifier_;
        manager = manager_;
    }

    function updateTreasury(address treasury_) external onlyOwner {
        if (treasury_ == address(0)) {
            revert InvalidAddress();
        }
        emit TreasuryUpdated(treasury, treasury_);
        treasury = treasury_;
    }

    function updateVerifier(address verifier_) external onlyOwner {
        verifier = verifier_;
    }

    function updateManager(address manager_) external onlyOwner {
        manager = manager_;
    }

    function registerToken(address token_) external onlyOwner {
        acceptedPayments[token_] = true;
        emit PaymentUpdated(token_, true);
    }

    function unregisterToken(address token_) external onlyOwner {
        if (!acceptedPayments[token_]) {
            revert UnregisteredToken();
        }
        delete acceptedPayments[token_];
        emit PaymentUpdated(token_, false);
    }
}
