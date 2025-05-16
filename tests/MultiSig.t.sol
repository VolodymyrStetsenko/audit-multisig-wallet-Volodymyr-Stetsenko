// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import "../src/MultiSig.sol";

contract MultiSigTest is Test {
    MultiSig public wallet;
    address[] public owners;

    function setUp() public {
        owners = new address ;
        owners[0] = address(0x1);
        owners[1] = address(0x2);
        owners[2] = address(0x3);
        wallet = new MultiSig(owners, 2);
    }

    function testOwnersSetCorrectly() public {
        assertTrue(wallet.isOwner(address(0x1)));
        assertTrue(wallet.isOwner(address(0x2)));
        assertTrue(wallet.isOwner(address(0x3)));
    }

    function testRequiredConfirmations() public {
        assertEq(wallet.required(), 2);
    }
}
