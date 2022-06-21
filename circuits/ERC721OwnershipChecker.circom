pragma circom 2.0.4;

include "../node_modules/circomlib/circuits/eddsamimc.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/mimc.circom";

template ERC721OwnershipChecker() {
  // Check if the original message ends with the token address
  signal input message[105];
  signal input tokenAddress[42];
  for (var i = 0; i < 42; i++) {
    message[48 + i] === tokenAddress[i];
  }

  // Check if the EdDSA signature is valid
  signal input pubKeyX;
  signal input pubKeyY;
  signal input R8x;
  signal input R8y;
  signal input S;
  signal input M;
  component verifier = EdDSAMiMCVerifier();
  verifier.enabled <== 1;
  verifier.Ax <== pubKeyX;
  verifier.Ay <== pubKeyY;
  verifier.R8x <== R8x;
  verifier.R8y <== R8y;
  verifier.S <== S;
  verifier.M <== M;

  // Check if the EdDSA's "M" is "message" hashed
  component mimc7 = MultiMiMC7(105, 91);
  mimc7.k <== 0;
  for (var i = 0; i < 105; i++) {
    mimc7.in[i] <== message[i];
  }
  M === mimc7.out;

  // Export the nullifier
  component bits2Num = Bits2Num(14);
  for (var i = 0; i < 14; i++) {
    bits2Num.in[i] <== message[91 + i];
  }
  signal output nullifier <== bits2Num.out;
}

component main{public [tokenAddress, pubKeyX]} = ERC721OwnershipChecker();
