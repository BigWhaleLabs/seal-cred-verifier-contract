# Verifier contract

Verifies a ZK proof of the following two claims:

1. User owns an attestation that they own an ERC721 token
2. User owns an attestation that they own an email ending in the specified domain name

## Usage

1. Clone the repository with `git clone git@github.com:BigWhaleLabs/seal-cred-verifier-contract.git`
2. Install the dependencies with `yarn`
3. Add environment variables to your `.env` file
4. Create an empty folder named `build` at the top most level of the repo
5. Run `yarn compile-circuit` to compile the circom circuits, create proof, verify proof, exports verifier as a solidity Verifier.sol
6. Run `yarn compile` to compile the contract
7. Run the scripts below

## Environment variables

| Name                         | Description                                   |
| ---------------------------- | --------------------------------------------- |
| `ETHERSCAN_API_KEY`          | Etherscan API key                             |
| `ETH_RPC`                    | Ethereum RPC URL (defaults to @bwl/constants) |
| `CONTRACT_OWNER_PRIVATE_KEY` | Private key of the contract owner             |

Also check out the `.env.example` file for more information.

## Available scripts

- `yarn build` — compiles the contract ts interface to the `typechain` directory
- `yarn compile-erc721` and `yarn compile-email` - compiles the circom circuits, creates proof, verifies proof, exports verifier as a solidity file
- `yarn test` — runs the test suite
- `yarn deploy` — deploys the contract to the network
- `yarn eth-lint` — runs the linter for the solidity contract
- `yarn lint` — runs all the linters
- `yarn prettify` — prettifies the code in th project
- `yarn release` — relases the `typechain` directory to NPM
