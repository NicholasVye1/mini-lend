// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MiniLend {
    // how much each person put in
    mapping(address => uint256) public deposited;
    // how much each person owes
    mapping(address => uint256) public borrowed;

    // you may borrow up to 50% of your deposit
    uint256 public constant COLLATERAL_FACTOR = 50;

    // put money in
    function deposit() external payable {
        require(msg.value > 0, "Send some ETH");
        deposited[msg.sender] += msg.value;
    }

    // borrow against your deposit
    function borrow(uint256 amount) external {
        uint256 maxBorrow = (deposited[msg.sender] * COLLATERAL_FACTOR) / 100;
        require(borrowed[msg.sender] + amount <= maxBorrow, "Not enough collateral");
        require(address(this).balance >= amount, "Pool is empty");

        borrowed[msg.sender] += amount;
        payable(msg.sender).transfer(amount);
    }

    // pay back what you owe
    function repay() external payable {
        require(borrowed[msg.sender] >= msg.value, "Paying back too much");
        borrowed[msg.sender] -= msg.value;
    }

    // take your deposit back (only if you owe nothing)
    function withdraw(uint256 amount) external {
        require(borrowed[msg.sender] == 0, "Repay your loan first");
        require(deposited[msg.sender] >= amount, "Not that much deposited");

        deposited[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
}