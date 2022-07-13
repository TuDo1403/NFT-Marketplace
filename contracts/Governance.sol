// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.13;

contract Governance {
    error Governance__Unauthorized();
    error Governance__InvalidAddress();
    error Governance__UnregisteredToken();

    address public manager;
    address public treasury;
    address public verifier;
    address public marketplace;

    mapping(address => bool) public acceptedPayments;

    event PaymentUpdated(address indexed token_, bool registed);
    event TreasuryUpdated(address indexed from_, address indexed to_);

    modifier onlyOwner() {
        if (msg.sender != manager) {
            revert Governance__Unauthorized();
        }
        _;
    }

    modifier validAddress(address addr_) {
        if (addr_ == address(0)) {
            revert Governance__InvalidAddress();
        }
        _;
    }

    // 363880
    constructor(
        address manager_,
        address treasury_,
        address verifier_
    ) validAddress(manager_) validAddress(treasury_) validAddress(verifier_) {
        manager = manager_;
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

    function updateManager(address manager_)
        external
        onlyOwner
        validAddress(manager_)
    {
        manager = manager_;
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
}
