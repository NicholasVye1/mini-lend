# MiniLend
An over-collateralized lending protocol written in Solidity and built with Foundry. Users deposit ETH as collateral and borrow a stablecoin against it. Loans accrue interest over time, collateral is valued through a price oracle, and unhealthy positions can be liquidated — the same core mechanics that power real DeFi protocols like Aave and Compound.

⚠️ Learning project. This contract is for educational purposes and is not audited. Do not deploy it to mainnet or use it with real funds.

## Features
- Deposit ETH as collateral.
- Borrow a stablecoin (mUSD) against that collateral, valued live by a price oracle.
- Interest accrual — debt grows over time at a fixed annual rate.
- Price oracle integration — collateral is valued in USD, so borrowing power moves with the ETH price.
- Liquidation — anyone can close an unhealthy position by repaying its debt and claiming its collateral.

## How it works
MiniLend separates the price of collateral from the value of debt, which is what makes a real lending market work: you lock up one asset (ETH) and borrow a different one (a USD stablecoin).

Collateral valuation. Deposited ETH is priced in USD using an on-chain oracle. In tests this is a mock feed I control; in production it would be a Chainlink price feed. The contract talks to either one through the same IPriceOracle interface, so the protocol logic never changes.

Borrowing limit (collateral factor: 50%). A user can borrow up to 50% of their collateral's USD value. Depositing 1 ETH worth $3,000 allows borrowing up to $1,500.

Interest (10% per year). Debt accrues simple interest over time. Whenever a borrower interacts with their position, the contract first "catches up" their accrued interest, then applies the new action. A view function, currentDebt, reports the live debt including interest at any moment.

Liquidation (threshold: 80%). If falling collateral value or accumulating interest pushes a borrower's debt above 80% of their collateral's worth, the position becomes liquidatable. Any third party can repay the outstanding debt in mUSD and receive the borrower's ETH collateral as the incentive. The gap between the 50% borrow limit and the 80% liquidation threshold gives healthy borrowers a safety buffer before they are at risk.

## Architecture
The protocol interacts with the stablecoin and the price feed through interfaces (IERC20 and IPriceOracle) rather than concrete contracts. This is what lets the same code run against mock implementations during testing and real contracts (such as USDC and Chainlink) in production, without modification.

## Project structure
mini-lend

src
MiniLend.sol
Test
MiniLend.t.sol
foundry.toml
README.md

## Running it yourself
You'll need Foundry installed.

Clone the
