# MiniLend

An over-collateralized lending protocol written in Solidity and built with [Foundry](https://book.getfoundry.sh/). Users deposit ETH as collateral and borrow a stablecoin against it. Loans accrue interest over time, collateral is valued through a price oracle, and unhealthy positions can be liquidated — the same core mechanics that power real DeFi protocols like Aave and Compound.

> ⚠️ **Learning project.** This contract is for educational purposes and is **not audited**. Do not deploy it to mainnet or use it with real funds.

---

## Features

- **Deposit ETH** as collateral.
- **Borrow a stablecoin** (mUSD) against that collateral, valued live by a price oracle.
- **Interest accrual** — debt grows over time at a fixed annual rate.
- **Price oracle integration** — collateral is valued in USD, so borrowing power moves with the ETH price.
- **Liquidation** — anyone can close an unhealthy position by repaying its debt and claiming its collateral.

## How it works

MiniLend separates the price of collateral from the value of debt, which is what makes a real lending market work: you lock up one asset (ETH) and borrow a different one (a USD stablecoin).

**Collateral valuation.** Deposited ETH is priced in USD using an on-chain oracle. In tests this is a mock feed we control; in production it would be a Chainlink price feed. The contract talks to either one through the same `IPriceOracle` interface, so the protocol logic never changes.

**Borrowing limit (collateral factor: 50%).** A user can borrow up to 50% of their collateral's USD value. Depositing 1 ETH worth $3,000 allows borrowing up to $1,500.

**Interest (10% per year).** Debt accrues simple interest over time. Whenever a borrower interacts with their position, the contract first "catches up" their accrued interest, then applies the new action. A view function, `currentDebt`, reports the live debt including interest at any moment.

**Liquidation (threshold: 80%).** If falling collateral value or accumulating interest pushes a borrower's debt above 80% of their collateral's worth, the position becomes liquidatable. Any third party can repay the outstanding debt in mUSD and receive the borrower's ETH collateral as the incentive. The gap between the 50% borrow limit and the 80% liquidation threshold gives healthy borrowers a safety buffer before they are at risk.

## Architecture

The protocol interacts with the stablecoin and the price feed through interfaces (`IERC20` and `IPriceOracle`) rather than concrete contracts. This is what lets the same code run against mock implementations during testing and real contracts (such as USDC and Chainlink) in production, without modification.

## Project structure

mini-lend
* src
    * MiniLend.sol 
* Test
    * MiniLend.t.sol 
* founary.toml
* README.md

## Running it yourself

You'll need [Foundry](https://book.getfoundry.sh/getting-started/installation) installed.

Clone the repository:

```bash
git clone https://github.com/NicholasVye1/mini-lend.git
cd mini-lend
```

Build the contracts:

```bash
forge build
```

Run the tests:

```bash
forge test
```

A passing run looks like this:
Ran 7 tests for test/MiniLend.t.sol:MiniLendTest

[PASS] testBorrowAgainstEthCollateral()

[PASS] testCannotBorrowOverLimit()

[PASS] testHealthyBorrowerCannotBeLiquidated()

[PASS] testInterestAccrues()

[PASS] testLiquidationAfterPriceCrash()

[PASS] testPriceDropLowersBorrowingPower()

[PASS] testRepay()

Suite result: ok. 7 passed; 0 failed; 0 skipped

## Test coverage

The suite exercises the full lifecycle of the protocol:

| Test | What it proves |
|------|----------------|
| `testBorrowAgainstEthCollateral` | A user can borrow stablecoin against ETH collateral, priced by the oracle. |
| `testCannotBorrowOverLimit` | Borrowing past the 50% collateral factor is rejected. |
| `testPriceDropLowersBorrowingPower` | When the ETH price falls, borrowing power shrinks automatically. |
| `testInterestAccrues` | Debt grows by the correct amount after time passes. |
| `testRepay` | A borrower can repay debt and clear their loan. |
| `testHealthyBorrowerCannotBeLiquidated` | A safe position cannot be liquidated. |
| `testLiquidationAfterPriceCrash` | After a price crash, an unhealthy position can be liquidated and its collateral claimed. |

## Security notes

Lending protocols are among the most-attacked contracts in DeFi. This is a learning project and deliberately omits protections that production code requires. Known limitations include:

- **Not audited** — none of this has been professionally reviewed.
- **Simple interest** — real protocols typically compound and use a utilization-based rate model.
- **Full liquidation** — a liquidator seizes all collateral rather than just enough to restore health; production protocols liquidate partially.
- **No reentrancy guard** — the contract should adopt the checks-effects-interactions pattern and use `call` instead of `transfer`.
- **Trusted oracle** — a real deployment must consider oracle manipulation and stale-price protection.

## Roadmap

- [x] Interest accrual
- [x] Price oracle integration
- [x] Liquidation
- [ ] Reentrancy protection (checks-effects-interactions + `call`)
- [ ] Partial liquidations with a liquidation bonus
- [ ] Compounding, utilization-based interest rates
- [ ] Multiple collateral and borrow assets
- [ ] Testnet deployment with a verified contract address

## License

MIT