#!/bin/sh
set -e

# Util function for logging
starEcho () {
  echo "**** $1 ****"
}

# Compile the circuit
starEcho "COMPILING CIRCUIT"
circom circuits/ERC721OwnershipChecker.circom --r1cs --wasm --sym --c -o build

# Generate witness
starEcho "GENERATING WITNESS FOR SAMPLE INPUT"
node build/ERC721OwnershipChecker_js/generate_witness.js build/ERC721OwnershipChecker_js/ERC721OwnershipChecker.wasm inputs/input.json build/witness.wtns

# Generate zkey 0000
starEcho "GENERATING ZKEY 0000"
yarn snarkjs groth16 setup build/ERC721OwnershipChecker.r1cs pot/pot16_final.ptau pot/ERC721OwnershipChecker_0000.zkey

# Generate reference zkey
# yarn snarkjs zkey new build/ERC721OwnershipChecker.r1cs pot/pot24_final.ptau pot/ERC721OwnershipChecker_0000.zkey

# Ceremony just like before but for zkey this time
# yarn snarkjs zkey contribute pot/ERC721OwnershipChecker_0000.zkey pot/ERC721OwnershipChecker_0001.zkey \
#   --name="First contribution" -v -e="$(head -n 4096 /dev/urandom | openssl sha1)"
# yarn snarkjs zkey contribute pot/ERC721OwnershipChecker_0001.zkey pot/ERC721OwnershipChecker_0002.zkey \
#   --name="Second contribution" -v -e="$(head -n 4096 /dev/urandom | openssl sha1)"
# yarn snarkjs zkey contribute pot/ERC721OwnershipChecker_0002.zkey pot/ERC721OwnershipChecker_0003.zkey \
#   --name="Third contribution" -v -e="$(head -n 4096 /dev/urandom | openssl sha1)"

#  Verify zkey
# yarn snarkjs zkey verify build/ERC721OwnershipChecker.r1cs pot/pot24_final.ptau pot/ERC721OwnershipChecker_0001.zkey

# Apply random beacon as before
starEcho "GENERATING FINAL ZKEY"
yarn snarkjs zkey beacon pot/ERC721OwnershipChecker_0000.zkey pot/ERC721OwnershipChecker_final.zkey \
  0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon phase2"

# Optional: verify final zkey
starEcho "VERIFYING FINAL ZKEY"
yarn snarkjs zkey verify build/ERC721OwnershipChecker.r1cs pot/pot16_final.ptau pot/ERC721OwnershipChecker_final.zkey

# Export verification key
starEcho "Exporting vkey"
yarn snarkjs zkey export verificationkey pot/ERC721OwnershipChecker_final.zkey pot/verification_key.json

# Create the proof
starEcho "CREATING PROOF FOR SAMPLE INPUT"
yarn snarkjs groth16 prove pot/ERC721OwnershipChecker_final.zkey build/witness.wtns \
  build/proof.json build/public.json

# Verify the proof
starEcho "VERIFYING PROOF FOR SAMPLE INPUT"
yarn snarkjs groth16 verify pot/verification_key.json build/public.json build/proof.json

# Smart contract commands
# Export the verifier as a smart contract
yarn snarkjs zkey export solidityverifier pot/ERC721OwnershipChecker_final.zkey contracts/Verifier.sol

# Create the solidity call data with the existing public.json and proof.json
# snarkjs zkey export soliditycalldata public.json proof.json
