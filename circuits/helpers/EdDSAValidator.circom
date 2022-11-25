pragma circom 2.0.4;

include "../../node_modules/@big-whale-labs/seal-hub-verifier-template/circomlib/circuits/eddsamimc.circom";
include "../../node_modules/@big-whale-labs/seal-hub-verifier-template/circomlib/circuits/mimc.circom";

// Check if the EdDSA signature is valid
template EdDSAValidator(messageLength) {
  // Get all inputs
  signal input pubKeyX;
  signal input pubKeyY;
  signal input R8x;
  signal input R8y;
  signal input S;
  signal input message[messageLength];
  // Hash message
  component mimc7 = MultiMiMC7(messageLength, 91);
  mimc7.k <== 0;
  for (var i = 0; i < messageLength; i++) {
    mimc7.in[i] <== message[i];
  }
  // Verify the signature
  component verifier = EdDSAMiMCVerifier();
  verifier.enabled <== 1;
  verifier.Ax <== pubKeyX;
  verifier.Ay <== pubKeyY;
  verifier.R8x <== R8x;
  verifier.R8y <== R8y;
  verifier.S <== S;
  verifier.M <== mimc7.out;
}