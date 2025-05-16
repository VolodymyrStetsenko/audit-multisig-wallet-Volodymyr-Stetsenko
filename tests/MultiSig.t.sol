// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../src/MultiSig.sol";

contract MultiSigTest is Test {
    MultiSig wallet;
    address[] owners;

    function setUp() public {
        owners = [address(1), address(2), address(3)];
        wallet = new MultiSig(owners, 2); // 2-of-3 wallet
        vm.deal(address(this), 1 ether); // даємо цьому контракту 1 ether
    }

    function testAddTransactionAndConfirm() public {
        wallet.addTransaction(address(4), 0.1 ether, "");

        wallet.confirmTransaction(0);
        wallet.confirmTransaction(0);

        wallet.executeTransaction(0);

        (, , , , bool executed) = wallet.transactions(0);
        assertTrue(executed);
    }
}
