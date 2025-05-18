// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract MockERC20 {
    mapping(address => uint256) public balances;

    function transfer(address recipient, uint256 amount) external returns (bool) {
        balances[recipient] += amount;
        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}
