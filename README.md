# Verifier contract

Verifies a ZK proof of the following two claims:

1. Prover owns an Ethereum address (the signature is valid)
2. This Ethereum address is a part of the given Merkle tree

## Usage

1. Clone the repository with `git clone git@github.com:BigWhaleLabs/seal-cred-verifier-contract.git`
2. Install the dependencies with `yarn`
3. Add environment variables to your `.env` file
4. Run `yarn download-ptau` to download ptau for proving
5. Run `yarn prove` to compile the circom circuits, create proof, verify proof, exports verifier as a solidity Verifier.sol
6. Run `yarn compile` to compile the contract
7. Run the scripts below for different commands

## Environment variables

| Name                         | Description                                   |
| ---------------------------- | --------------------------------------------- |
| `ETHERSCAN_API_KEY`          | Etherscan API key                             |
| `ETH_RPC`                    | Ethereum RPC URL (defaults to @bwl/constants) |
| `CONTRACT_OWNER_PRIVATE_KEY` | Private key of the contract owner             |

Also check out the `.env.example` file for more information.

## Available scripts

- `yarn compile` — compiles the contract ts interface to the `typechain` directory
- `yarn test` — runs the test suite
- `yarn deploy` — deploys the contract to the network
- `yarn eth-lint` — runs the linter for the solidity contract
- `yarn lint` — runs all the linters
- `yarn prettify` — prettifies the code in th project
- `yarn release` — relases the `typechain` directory to NPM
- `yarn prove` - compiles the circom circuits, creates proof, verifies proof, exports verifier as a solidity Verifier.sol
- `yarn download-ptau` - downloads the required pot24_final.ptau
