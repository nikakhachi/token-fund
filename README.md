# Token Fund.

This project implements an Governable TokenFund smart contract, with the implementation of Uniswap and Sushiswap DEXes where:

- Users can deposit USDT or USDC.
- Contract will swap these assets 50% to LINK and 50% to WETH with the best price available between Uniswap and Sushiswap.
- Contract will mint fund tokens to the user who deposited, which will represent the share in the LINK and WETH asset pool.
- Contract will use these LINK and WETH tokens to gain a profit.
- On the user withdrawal, the tokens allocated for the user will be calculated by the shares, swapped to USDT or USDC and transferred back to user.
- If the contract made some profit on the user's deposit, contract will take 10% of the profit.

The development tool used is the Foundry where the contracts and the tests are written, and then there's Hardhat integrated which is used for writing the deployment and upgrade scripts.

## Table of Contents

- [Features](#features)
- [Testing](#testing)
- [Deploying](#deploying)

## Features

- **_depositUSDC_** - Users can deposit USDC by calling this function. Contract will then find the best price to swap it 50%-50% and WETH and LINK, swap it and mint the shares token to the user to represent his shares in the LINK and WETH asset pool.

- **_depositUSDT_** - Users can deposit USDT by calling this function. Contract will then find the best price to swap it 50%-50% and WETH and LINK, swap it and mint the shares token to the user to represent his shares in the LINK and WETH asset pool.

The 2 functions above are separated. It could have been done in one function but then the extra check would have been needed. So by this implementation, yes I increase the gas cost of the contract deployment, but from the user perspective gas costs will be cheaper.

- **_withdrawUSDC_** - Users can withdraw all their funds from the contract by calling this function. The LINK and WETH allocation for them will be calculate by their number of shares (formula is the same as in calculation of shares when providing/removing liquidity in AMM). LINK and WETH will be swapped to USDC for the best price and transferred to user. If the contract made some profits on users funds, it will take 10% profit fee.

- **_withdrawUSDT_** - Users can withdraw all their funds from the contract by calling this function. The LINK and WETH allocation for them will be calculate by their number of shares (formula is the same as in calculation of shares when providing/removing liquidity in AMM). LINK and WETH will be swapped to USDT for the best price and transferred to user. If the contract made some profits on users funds, it will take 10% profit fee.

The same goes for the 2 functions above. By this implementation, yes I increase the gas cost of the contract deployment, but from the user perspective gas costs will be cheaper.

- **_withdrawProfits_** - This is the admins (deployer's) function to withdraw all the profits from the contracts.

- **_mintShares_** - This internal function calculates amount of shares that should be given to user based on their provided assets and the existing assets. The formula used here is the same as in calculation of shares when providing/removing liquidity in AMM

- **_timeLockFunction_** - DEMONSTRATIONAL PURPOSES FUNCTION. This function can be called by the TimeLock to demonstrate the governance functionality.

- **_swapForBestPrice_** - This internal function takes the list of tokens for the swap and checks the swap prices for the Uniswap and the Sushiswap. Add then swaps the tokens for the best prices.

## Testing

Tests are written to cover as many scenarios as possible, but still, it's not enough for production. This should never happen in production-ready code!

To run the tests, you will have to do the following

IMPORTANT1: You will have to test it on Mainnet fork as the token/contract addresses used in tests are mainnet addresses.
IMPORTANT2: Please make sure you specify the block number 18032971 as a fork block number. This will make sure the Governance tests are passing correctly.

1. Clone this repository to your local machine.
2. Run `forge install`.
3. Run `forge build`.
4. Run `forge test --fork-block-number 18032971 --fork-url {MAINNET_RPC_URL}`.

OR, you can just run `forge test --fork-block-number 18032971 --fork-url {MAINNET_RPC_URL}`, which will automatically install dependencies and compile the contracts.

## Deploying

To deploy the smart contract do the following:

1. Update the variables in files of the `script/` folder to your needs.
2. Deploy the smart contract with `forge script script/TokenFund.s.sol --fork-url {RPC_URL} --broadcast`

To deploy the smart contract locally you can run:

1. `anvil` to run a local node.

And then follow the 2 steps above and replace `{RPC_URL}` in step2 with `http://localhost:8545`

Read More About the Deployment from the [Foundry Book](https://book.getfoundry.sh/forge/deploying)
