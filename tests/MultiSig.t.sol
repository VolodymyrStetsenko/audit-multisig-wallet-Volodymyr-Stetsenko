// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/MultiSig.sol";

contract MultiSigTest is Test {
    MultiSig wallet;

    address[] owners = [address(1), address(2), address(3)];

    function setUp() public {
        wallet = new MultiSig(owners, 2);
    }

    function testOwnersSetCorrectly() public {
        assertTrue(wallet.isOwner(address(1)));
        assertTrue(wallet.isOwner(address(2)));
        assertTrue(wallet.isOwner(address(3)));
    }

    function testRequiredConfirmations() public {
        assertEq(wallet.required(), 2);
    }
}
