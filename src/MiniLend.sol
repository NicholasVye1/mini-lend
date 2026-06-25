// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MiniLend {
    mapping(address => uint256) public deposited;
    mapping(address => uint256) public borrowed;      // debt as of the last catch-up
    mapping(address => uint256) public lastAccrued;   // NEW: when we last caught up their interest

    uint256 public constant COLLATERAL_FACTOR = 50;       // borrow up to 50% of deposit
    uint256 public constant INTEREST_RATE = 10;           // NEW: 10% per year
    uint256 public constant SECONDS_PER_YEAR = 365 days;  // NEW: helper for the math

    // NEW: pile up any interest owed since last time, then reset their clock
    function _accrue(address user) internal {
        uint256 principal = borrowed[user];
        if (principal > 0) {
            uint256 timeElapsed = block.timestamp - lastAccrued[user];
            uint256 interest = (principal * INTEREST_RATE * timeElapsed) / (100 * SECONDS_PER_YEAR);
            borrowed[user] = principal + interest;
        }
        lastAccrued[user] = block.timestamp;
    }

    // NEW: peek at what someone owes right now, interest included
    function currentDebt(address user) public view returns (uint256) {
        uint256 principal = borrowed[user];
        if (principal == 0) return 0;
        uint256 timeElapsed = block.timestamp - lastAccrued[user];
        uint256 interest = (principal * INTEREST_RATE * timeElapsed) / (100 * SECONDS_PER_YEAR);
        return principal + interest;
    }

    function deposit() external payable {
        require(msg.value > 0, "Send some ETH");
        deposited[msg.sender] += msg.value;
    }

    function borrow(uint256 amount) external {
        _accrue(msg.sender);   // NEW: catch up interest before anything else
        uint256 maxBorrow = (deposited[msg.sender] * COLLATERAL_FACTOR) / 100;
        require(borrowed[msg.sender] + amount <= maxBorrow, "Not enough collateral");
        require(address(this).balance >= amount, "Pool is empty");

        borrowed[msg.sender] += amount;
        payable(msg.sender).transfer(amount);
    }

    function repay() external payable {
        _accrue(msg.sender);   // NEW: catch up interest before subtracting
        require(borrowed[msg.sender] >= msg.value, "Paying back too much");
        borrowed[msg.sender] -= msg.value;
    }

    function withdraw(uint256 amount) external {
        _accrue(msg.sender);   // NEW
        require(borrowed[msg.sender] == 0, "Repay your loan first");
        require(deposited[msg.sender] >= amount, "Not that much deposited");

        deposited[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
}