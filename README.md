**MiniLend**

A minimal, over-collateralized lending protocol written in Solidity, built with Foundry. Users deposit ETH as collateral, borrow against it, repay their loans, and withdraw their funds, all enforced by a smart contract.

**Learning project.** This contract is for educational purposes and is not audited. Do not deploy it to mainnet or use it with real funds.


**What it does:**

MiniLend captures the core mechanics that power real DeFi lending protocols (like Aave and Compound), stripped down to their essentials:

* Deposit - Put ETH into the protocol as collateral.
* Borrow — Borrow ETH against your deposit, up to a fixed collateralization limit.
* Repay — Pay back what you owe.
* Withdraw — Take your collateral back, once your debt is cleared.

Every rule is enforced on-chain. The contract will refuse any action that breaks the rules, for example: borrowing more than your collateral allows, or withdrawing while you still owe money.

**How the borrowing math works**

MiniLend is **over-collateralized**, meaning you can only borrow a fraction of what you deposit. This is what protects the protocol: your locked collateral is always worth more than your loan.

The limit is set by the collateral factor:

maxBorrow = deposit × COLLATERAL_FACTOR / 100

With COLLATERAL_FACTOR = 50, depositing 1 ETH lets you borrow up to 0.5 ETH. The contract checks this on every borrow and rejects anything over the limit.

**Project structure**

mini-lend

* src
    * MiniLend.sol        # The lending protocol contract
* test
    * MiniLend.t.sol      # Foundry tests
* foundry.toml            # Foundry configuration
* README.md

**Running it yourself**

You'll need Foundry installed.

Clone the repository:

bashgit clone https://github.com/NicholasVye1/mini-lend.git
cd mini-lend

Build the contracts:

bashforge build

Run the tests:

bashforge test

A passing run looks like this:

[PASS] testDepositAndBorrow() (gas: 72897)
Suite result: ok. 1 passed; 0 failed; 0 skipped


**License**

MIT