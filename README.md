# seal-cred-verifier-contract

# Commands

Hardhat set-up

```shell
npm install --save-dev hardhat
npx hardhat
```

circomlib installation

```shell
npm i circomlib
```

Steps to set up merkle tree and ecdsa:

1. Run `yarn`
2. Generate input.json by creating MerkleTree and ECDSA inputs. Generate root, leaf, pathIndices, siblings from [`seal-cred-derivatives-contract/merkle-tree-generator`](https://github.com/BigWhaleLabs/seal-cred-derivatives-contract-verifier) and paste into `input.json`. Genereate r, s, msghash, pubkey by running

```
yarn generate-ecdsa
```

and paste the `inputs/input_verify0.json` into `input.json`

3. Run

```
yarn verify-proof
```

If running into memory problems (node):

```
export NODE_OPTIONS=--max_old_space_size=196608
```

If running into memory problems (OS): Add the below line to `/etc/sysctl.conf`

```
vm.max_map_count=196608
```

It took 2.5-3 hours to finish verify proof on a 24 vCPU, 192GB RAM, 600GB disk server.
