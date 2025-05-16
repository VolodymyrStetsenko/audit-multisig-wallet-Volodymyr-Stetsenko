// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet wallet;
    address[] public owners;
    address alice = address(0x1);
    address bob = address(0x2);
    address carol = address(0x3);

    function setUp() public {
        owners.push(alice);
        owners.push(bob);
        owners.push(carol);
        wallet = new MultiSigWallet(owners, 2);
        vm.deal(address(wallet), 10 ether);
    }

    function testAddTransactionAndConfirm() public {
        vm.prank(alice);
        wallet.executeERC20Transfer(address(0), address(0x99), 100);

        assertEq(wallet.getTransactionCount(), 1);
        (address dest, , , bool executed) = wallet.transactions(0);
        assertEq(dest, address(0));
        assertFalse(executed);
    }

    function testExecuteWithEnoughConfirmations() public {
        // Add ERC20 transfer txn
        vm.prank(alice);
        wallet.executeERC20Transfer(address(0xABC), address(0x999), 500);

        // Confirm from second owner
        vm.prank(bob);
        wallet.confirmTransaction(0);

        (, , , bool executed) = wallet.transactions(0);
        assertTrue(executed);
    }

    function testRevertsIfDoubleConfirm() public {
        vm.prank(alice);
        wallet.executeERC20Transfer(address(0xABC), address(0x999), 500);

        vm.prank(alice);
        vm.expectRevert("Already confirmed");
        wallet.confirmTransaction(0);
    }

    function testRevertsIfNotOwner() public {
        vm.prank(address(0xdead));
        vm.expectRevert("Only owners can confirm");
        wallet.confirmTransaction(0);
    }
}
