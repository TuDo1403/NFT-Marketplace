// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;

contract GasTest {
    mapping(address => uint256) balances;

    function multiply(uint256 val_, uint256 mul_, uint256 div_) external {
        uint256 val = (mul_ * val_) / div_;
        balances[msg.sender] = val;
    }

    function multiply2(uint256 val_, uint256 mul_, uint256 div_) external {
        uint256 val = (mul_ * val_) / div_;
        balances[msg.sender] = val;
    }
    function multiply3(uint256 val_, uint256 n_bits_) external {
        uint256 val = val_ >> n_bits_;
        balances[msg.sender] = val;
    }
}