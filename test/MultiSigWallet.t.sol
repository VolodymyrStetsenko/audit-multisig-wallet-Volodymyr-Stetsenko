// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MaliciousReceiver.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet wallet;
    address alice = address(0x1);
    address bob   = address(0x2);
    address carol = address(0x3);
    address[] owners;

    function setUp() public {
        owners.push(alice);
        owners.push(bob);
        owners.push(carol);

        wallet = new MultiSigWallet(owners, 2);
        vm.deal(address(wallet), 10 ether);
    }

    /* --------------------------------------------------------------------- */
    /*                       ─── initial positive tests ───               */
    /* --------------------------------------------------------------------- */

    function testAddTransactionAndConfirm() public {
        vm.prank(alice);
        wallet.executeERC20Transfer(address(0xABC), address(0x999), 100);

        assertEq(wallet.getTransactionCount(), 1);

        (address dest, uint value,, bool executed) = wallet.transactions(0);
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

    /* --------------------------------------------------------------------- */
    /*                         ─── нnegative branches ───                       */
    /* --------------------------------------------------------------------- */

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

    /* --------------------------------------------------------------------- */
    /*                     ─── integration with Mock ERC20 ───                   */
    /* --------------------------------------------------------------------- */

    function testERC20MockTransfer() public {
        MockERC20 token = new MockERC20();

        vm.prank(alice);
        wallet.executeERC20Transfer(address(token), address(0x999), 123);

        vm.prank(bob);
        wallet.confirmTransaction(0);

        assertEq(token.balanceOf(address(0x999)), 123);
    }

    /* --------------------------------------------------------------------- */
    /*                          ─── receive() ───                       */
    /* --------------------------------------------------------------------- */

    function testReceiveEther() public {
        vm.deal(address(this), 1 ether);

        (bool ok, ) = address(wallet).call{value: 1 ether}("");
        assertTrue(ok);
        assertEq(address(wallet).balance, 11 ether);
    }

    /* --------------------------------------------------------------------- */
    /*                     ─── proof-of-concept reentrancy ───               */
    /* --------------------------------------------------------------------- */

    function testReentrancy() public {
        // 1) Деплоїмо контракт-атакер і записуємо адресу
        MaliciousReceiver attacker = new MaliciousReceiver();
        address attackerAddr = address(attacker);

        // 2) Формуємо масив власників, де attacker також owner
        address;
        evilOwners[0] = alice;
        evilOwners[1] = attackerAddr;
        evilOwners[2] = bob;

        // 3) Деплоїмо мультисиг і прив’язуємо до атакера
        MultiSigWallet evilWallet = new MultiSigWallet(evilOwners, 2);
        attacker.initWallet(address(evilWallet));

        vm.deal(address(evilWallet), 5 ether); // баланс є

        // 4) Alice створює транзакцію на адресу attacker
        vm.prank(alice);
        evilWallet.executeERC20Transfer(attackerAddr, address(0), 0);

        // 5) Bob (attacker) підтверджує – 1-ше підтвердження
        vm.prank(attackerAddr);
        evilWallet.confirmTransaction(0);

        // 6) Alice дає друге підтвердження – під час виконання attacker спробує повторно
        vm.prank(alice);
        vm.expectRevert();           // очікуємо, що повторна confirm зірветься
        evilWallet.confirmTransaction(0);
    }
}
