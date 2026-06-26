// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MiniLend.sol";

// A tiny fake stablecoin so we can test borrowing a "dollar" token.
contract MockUSD {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "balance");
        require(allowance[from][msg.sender] >= amount, "allowance");
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

// A tiny fake price feed we can set by hand.
contract MockOracle {
    uint256 public price;
    constructor(uint256 _price) { price = _price; }
    function setPrice(uint256 _price) external { price = _price; }
    function latestPrice() external view returns (uint256) { return price; }
}

contract MiniLendTest is Test {
    MiniLend lend;
    MockUSD usd;
    MockOracle oracle;

    function setUp() public {
        usd = new MockUSD();
        oracle = new MockOracle(3000e18);          // start: ETH = $3000
        lend = new MiniLend(address(usd), address(oracle));
        usd.mint(address(lend), 1_000_000e18);     // give the pool $1,000,000 to lend
    }

    function testBorrowAgainstEthCollateral() public {
        vm.deal(address(this), 1 ether);
        lend.deposit{value: 1 ether}();            // 1 ETH collateral, worth $3000
        lend.borrow(1500e18);                      // 50% of $3000 = $1500 max
        assertEq(lend.borrowed(address(this)), 1500e18);
        assertEq(usd.balanceOf(address(this)), 1500e18);
    }

    function testCannotBorrowOverLimit() public {
        vm.deal(address(this), 1 ether);
        lend.deposit{value: 1 ether}();
        vm.expectRevert("Not enough collateral");
        lend.borrow(1600e18);                      // over the $1500 limit
    }

    function testPriceDropLowersBorrowingPower() public {
        vm.deal(address(this), 1 ether);
        lend.deposit{value: 1 ether}();
        oracle.setPrice(2000e18);                  // ETH falls to $2000
        vm.expectRevert("Not enough collateral");
        lend.borrow(1100e18);                      // new max is only $1000
        lend.borrow(1000e18);                      // exactly the new limit works
        assertEq(lend.borrowed(address(this)), 1000e18);
    }

    function testInterestAccrues() public {
        vm.deal(address(this), 1 ether);
        lend.deposit{value: 1 ether}();
        lend.borrow(1000e18);
        vm.warp(block.timestamp + 365 days);       // jump forward a year
        assertEq(lend.currentDebt(address(this)), 1100e18); // +10%
    }

    function testRepay() public {
        vm.deal(address(this), 1 ether);
        lend.deposit{value: 1 ether}();
        lend.borrow(1000e18);
        usd.approve(address(lend), 1000e18);       // allow the pool to pull mUSD back
        lend.repay(1000e18);
        assertEq(lend.borrowed(address(this)), 0);
    }

    receive() external payable {}
}