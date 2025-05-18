// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";
import "./mocks/MockERC20.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet wallet;
    address alice = address(0x1);
    address bob = address(0x2);
    address carol = address(0x3);
    address[] owners;

    function setUp() public {
        owners.push(alice);
        owners.push(bob);
        owners.push(carol);

        wallet = new MultiSigWallet(owners, 2);
        vm.deal(address(wallet), 10 ether);
    }

    function testAddTransactionAndConfirm() public {
        vm.prank(alice);
        wallet.executeERC20Transfer(address(0xABC), address(0x999), 100);

        assertEq(wallet.getTransactionCount(), 1);

        (
            address dest,
            uint value,
            bytes memory data,
            bool executed
        ) = wallet.transactions(0);

        assertEq(dest, address(0xABC));
        assertEq(value, 0);
        assertFalse(executed);
    }

    function testExecuteWithEnoughConfirmations() public {
        vm.prank(alice);
        wallet.executeERC20Transfer(address(0xABC), address(0x999), 500);

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

    function testRevertsIfExecuted() public {
        vm.prank(alice);
        wallet.executeERC20Transfer(address(0xABC), address(0x999), 500);

        vm.prank(bob);
        wallet.confirmTransaction(0);

        vm.prank(carol);
        vm.expectRevert("Transaction already executed");
        wallet.confirmTransaction(0);
    }

    function testERC20MockTransfer() public {
        MockERC20 token = new MockERC20();

        vm.prank(alice);
        wallet.executeERC20Transfer(address(token), address(0x999), 123);

        vm.prank(bob);
        wallet.confirmTransaction(0);

        uint256 balance = token.balanceOf(address(0x999));
        assertEq(balance, 123);
    }

    function testReceiveEther() public {
        vm.deal(address(this), 1 ether);
        (bool success, ) = address(wallet).call{value: 1 ether}("");
        assertTrue(success);
        assertEq(address(wallet).balance, 11 ether);
    }
}
