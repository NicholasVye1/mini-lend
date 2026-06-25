// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MiniLend.sol";

contract MiniLendTest is Test {
    MiniLend lend;

    function setUp() public {
        lend = new MiniLend();
    }

    function testDepositAndBorrow() public {
        vm.deal(address(this), 1 ether);   // give ourselves 1 fake ETH

        lend.deposit{value: 1 ether}();    // put 1 ETH in
        assertEq(lend.deposited(address(this)), 1 ether);

        lend.borrow(0.5 ether);            // borrow the max (half)
        assertEq(lend.borrowed(address(this)), 0.5 ether);
    }

    receive() external payable {}          // lets this test receive ETH
}