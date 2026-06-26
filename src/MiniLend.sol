// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// An interface is just a "menu" of functions something has.
// It lets MiniLend talk to ANY token or price feed — fake (for testing)
// or real (like USDC and Chainlink) — without caring how they work inside.
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IPriceOracle {
    function latestPrice() external view returns (uint256); // USD per 1 ETH, scaled by 1e18
}

contract MiniLend {
    mapping(address => uint256) public deposited;    // ETH collateral, in wei
    mapping(address => uint256) public borrowed;     // debt in mUSD (since last catch-up)
    mapping(address => uint256) public lastAccrued;

    uint256 public constant COLLATERAL_FACTOR = 50;       // borrow up to 50% of collateral value
    uint256 public constant INTEREST_RATE = 10;           // 10% per year
    uint256 public constant SECONDS_PER_YEAR = 365 days;

    IERC20 public usd;            // the stablecoin people borrow
    IPriceOracle public oracle;   // tells us the ETH price

    constructor(address _usd, address _oracle) {
        usd = IERC20(_usd);
        oracle = IPriceOracle(_oracle);
    }

    // pile up interest owed since last time, then reset the clock
    function _accrue(address user) internal {
        uint256 principal = borrowed[user];
        if (principal > 0) {
            uint256 timeElapsed = block.timestamp - lastAccrued[user];
            uint256 interest = (principal * INTEREST_RATE * timeElapsed) / (100 * SECONDS_PER_YEAR);
            borrowed[user] = principal + interest;
        }
        lastAccrued[user] = block.timestamp;
    }

    // peek at live debt, interest included
    function currentDebt(address user) public view returns (uint256) {
        uint256 principal = borrowed[user];
        if (principal == 0) return 0;
        uint256 timeElapsed = block.timestamp - lastAccrued[user];
        uint256 interest = (principal * INTEREST_RATE * timeElapsed) / (100 * SECONDS_PER_YEAR);
        return principal + interest;
    }

    // how much your ETH collateral is worth, in mUSD
    function collateralValue(address user) public view returns (uint256) {
        uint256 price = oracle.latestPrice();      // USD per ETH, scaled 1e18
        return (deposited[user] * price) / 1e18;   // result in mUSD
    }

    function deposit() external payable {
        require(msg.value > 0, "Send some ETH");
        deposited[msg.sender] += msg.value;
    }

    // amount is in mUSD
    function borrow(uint256 amount) external {
        _accrue(msg.sender);
        uint256 maxBorrow = (collateralValue(msg.sender) * COLLATERAL_FACTOR) / 100;
        require(borrowed[msg.sender] + amount <= maxBorrow, "Not enough collateral");
        require(usd.balanceOf(address(this)) >= amount, "Pool is empty");

        borrowed[msg.sender] += amount;
        usd.transfer(msg.sender, amount);
    }

    // pay back mUSD (you must approve the contract first)
    function repay(uint256 amount) external {
        _accrue(msg.sender);
        require(borrowed[msg.sender] >= amount, "Paying back too much");
        usd.transferFrom(msg.sender, address(this), amount);
        borrowed[msg.sender] -= amount;
    }

    function withdraw(uint256 amount) external {
        _accrue(msg.sender);
        require(borrowed[msg.sender] == 0, "Repay your loan first");
        require(deposited[msg.sender] >= amount, "Not that much deposited");

        deposited[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
}