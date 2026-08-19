# MiniLend

An over-collateralised lending protocol written in Solidity and built with Foundry. Users deposit ETH as collateral and borrow a stablecoin against it. Loans accrue interest over time, collateral is valued through a price oracle, and unhealthy positions can be liquidated — the same core mechanics that power real DeFi protocols like Aave and Compound.

I built this to properly understand how those mechanics fit together, rather than just reading about them. Everything below is what it does, how it works, and — just as importantly — what it doesn't do yet.

## What it does

- Deposit ETH as collateral.
- Borrow a stablecoin (mUSD) against that collateral, valued live by a price oracle.
- Accrue interest on outstanding debt at a fixed annual rate.
- Get liquidated — if a position becomes unhealthy, anyone can close it by repaying its debt and claiming the collateral.

## How it works

The core idea behind any lending market is separating the price of collateral from the value of debt: you lock up one asset and borrow a different one. MiniLend does this with ETH as collateral and a USD-pegged stablecoin (mUSD) as debt.

**Collateral valuation.** Deposited ETH is priced in USD through an on-chain oracle. In the test suite this is a mock feed I control; in production it would be a Chainlink price feed. The contract only ever talks to an `IPriceOracle` interface, so swapping the mock for a real feed doesn't touch the protocol logic at all.

**Borrowing limit — 50% collateral factor.** A user can borrow up to 50% of their collateral's USD value. Deposit 1 ETH worth $3,000, and you can borrow up to $1,500 in mUSD.

**Interest — 10% per year.** Debt accrues simple interest over time. Every time a borrower interacts with their position, the contract first catches up the accrued interest, then applies the new action on top. A `currentDebt` view function reports live debt, interest included, at any moment.

**Liquidation — 80% threshold.** If falling collateral value or accumulating interest pushes a borrower's debt above 80% of their collateral's worth, the position becomes liquidatable. Anyone can step in, repay the outstanding mUSD, and take the ETH collateral as their incentive. The gap between the 50% borrow limit and the 80% liquidation threshold is deliberate — it's the safety buffer that keeps a healthy borrower from being liquidated over a small price wobble.

## Architecture

The protocol talks to the stablecoin and the price feed through interfaces (`IERC20` and `IPriceOracle`) rather than concrete contracts. That's what lets the exact same code run against mock implementations in testing and real contracts — USDC, Chainlink — in production, with no changes needed.

## Project structure

```
mini-lend/
├── src/
│   └── MiniLend.sol
├── test/
│   └── MiniLend.t.sol
├── foundry.toml
└── README.md
```

## Running it yourself

You'll need [Foundry](https://book.getfoundry.sh/getting-started/installation) installed.

Clone the repository:
```
git clone https://github.com/NicholasVye1/mini-lend.git
cd mini-lend
```

Build the contracts:
```
forge build
```

Run the tests:
```
forge test
```

A passing run looks like this:
```
Ran 7 tests for test/MiniLend.t.sol:MiniLendTest
[PASS] testBorrowAgainstEthCollateral()
[PASS] testCannotBorrowOverLimit()
[PASS] testHealthyBorrowerCannotBeLiquidated()
[PASS] testInterestAccrues()
[PASS] testLiquidationAfterPriceCrash()
[PASS] testPriceDropLowersBorrowingPower()
[PASS] testRepay()

Suite result: ok. 7 passed; 0 failed; 0 skipped
```

## Test coverage

The suite exercises the full lifecycle of the protocol, from a healthy borrow through to a forced liquidation:

| Test | What it proves |
|---|---|
| `testBorrowAgainstEthCollateral` | A user can borrow stablecoin against ETH collateral, priced by the oracle. |
| `testCannotBorrowOverLimit` | Borrowing past the 50% collateral factor is rejected. |
| `testPriceDropLowersBorrowingPower` | When the ETH price falls, borrowing power shrinks automatically. |
| `testInterestAccrues` | Debt grows by the correct amount after time passes. |
| `testRepay` | A borrower can repay debt and clear their loan. |
| `testHealthyBorrowerCannotBeLiquidated` | A safe position cannot be liquidated. |
| `testLiquidationAfterPriceCrash` | After a price crash, an unhealthy position can be liquidated and its collateral claimed. |

## Security notes

Lending protocols are among the most-attacked contracts in DeFi, so it's worth being upfront about what this one doesn't do. This is a learning project, and it deliberately leaves out protections that production code would need:

- **Not audited** — none of this has been professionally reviewed.
- **Simple interest** — real protocols typically compound and use a utilisation-based rate model.
- **Full liquidation** — a liquidator seizes all collateral rather than just enough to restore health; production protocols liquidate partially.
- **No reentrancy guard** — the contract should adopt the checks-effects-interactions pattern and use `call` instead of `transfer`.
- **Trusted oracle** — a real deployment would need to guard against oracle manipulation and stale prices.

## Roadmap

- [x] Interest accrual
- [x] Price oracle integration
- [x] Liquidation
- [ ] Reentrancy protection (checks-effects-interactions + `call`)
- [ ] Partial liquidations with a liquidation bonus
- [ ] Compounding, utilisation-based interest rates
- [ ] Multiple collateral and borrow assets
- [ ] Testnet deployment with a verified contract address

## License

MIT

---
