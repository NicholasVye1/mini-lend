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
function testInterestAccrues() public {
        vm.deal(address(this), 1 ether);
        lend.deposit{value: 1 ether}();
        lend.borrow(0.5 ether);              // owe 0.5 ETH

        vm.warp(block.timestamp + 365 days); // jump forward one year ⏩

        uint256 debt = lend.currentDebt(address(this));
        assertEq(debt, 0.55 ether);          // 0.5 + 10% interest = 0.55
    }
    receive() external payable {}          // lets this test receive ETH
}