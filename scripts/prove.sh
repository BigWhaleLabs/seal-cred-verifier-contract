#!/bin/sh
set -e

# Phase 2
# circuit-specific stuff

# Compile the circuit
echo "****COMPILING CIRCUIT****"
circom circuits/MerkleTreeChecker.circom --r1cs --wasm --sym --c -o build

# Generate witness
echo "****GENERATING WITNESS FOR SAMPLE INPUT****"
node build/MerkleTreeChecker_js/generate_witness.js build/MerkleTreeChecker_js/MerkleTreeChecker.wasm input.json build/witness.wtns

# Setup (use plonk so we can skip ptau phase 2, generate zkey 0000
echo "****GENERATING ZKEY 0000****"
yarn snarkjs groth16 setup build/MerkleTreeChecker.r1cs pot/pot24_final.ptau pot/OwnershipChecker_0000.zkey

# Generate reference zkey
# yarn snarkjs zkey new build/MerkleTreeChecker.r1cs pot/pot24_final.ptau pot/MerkleTreeChecker_0000.zkey

# Ceremony just like before but for zkey this time
# yarn snarkjs zkey contribute pot/MerkleTreeChecker_0000.zkey pot/MerkleTreeChecker_0001.zkey \
#   --name="First contribution" -v -e="$(head -n 4096 /dev/urandom | openssl sha1)"
# yarn snarkjs zkey contribute pot/MerkleTreeChecker_0001.zkey pot/MerkleTreeChecker_0002.zkey \
#   --name="Second contribution" -v -e="$(head -n 4096 /dev/urandom | openssl sha1)"
# yarn snarkjs zkey contribute pot/MerkleTreeChecker_0002.zkey pot/MerkleTreeChecker_0003.zkey \
#   --name="Third contribution" -v -e="$(head -n 4096 /dev/urandom | openssl sha1)"

#  Verify zkey
# yarn snarkjs zkey verify build/MerkleTreeChecker.r1cs pot/pot24_final.ptau pot/MerkleTreeChecker_0001.zkey

# Apply random beacon as before
echo "****GENERATING FINAL ZKEY****"
yarn snarkjs zkey beacon pot/OwnershipChecker_0000.zkey pot/OwnershipChecker_final.zkey \
  0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon phase2"

# Optional: verify final zkey
echo "****VERIFYING FINAL ZKEY****"
yarn snarkjs zkey verify build/MerkleTreeChecker.r1cs pot/pot24_final.ptau pot/OwnershipChecker_final.zkey

# Export verification key
echo "** Exporting vkey"
yarn snarkjs zkey export verificationkey pot/OwnershipChecker_final.zkey pot/verification_key.json

# Create the proof
echo "****CREATING PROOF FOR SAMPLE INPUT****"
yarn snarkjs groth16 prove pot/OwnershipChecker_final.zkey build/witness.wtns \
  build/proof.json build/public.json

# Verify the proof
echo "****VERIFYING PROOF FOR SAMPLE INPUT****"
yarn snarkjs groth16 verify pot/verification_key.json build/public.json build/proof.json

# Smart contract commands
# Export the verifier as a smart contract
yarn snarkjs zkey export solidityverifier pot/MerkleTreeChecker_final.zkey contracts/Verifier.sol

# Create the solidity call data with the existing public.json and proof.json
# snarkjs zkey export soliditycalldata public.json proof.json
