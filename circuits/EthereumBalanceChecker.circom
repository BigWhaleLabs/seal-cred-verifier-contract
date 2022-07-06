pragma circom 2.0.4;

include "../node_modules/circomlib/circuits/eddsamimc.circom";
include "../node_modules/circomlib/circuits/mimc.circom";
include "../node_modules/circomlib/circuits/comparators.circom";
include "./Nullify.circom";

template EthereumBalanceChecker() {
  var addressLength = 42;
  var networkLength = 1;
  var messageLength = addressLength + networkLength;
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
  signal input message[messageLength];
  signal input balance;

  component mimc7 = MultiMiMC7(messageLength + 1, 91);
  mimc7.k <== 0;
  for (var i = 0; i < messageLength; i++) {
    mimc7.in[i] <== message[i];
  }
  mimc7.in[messageLength] <== balance;
  M === mimc7.out;
  // Get the network
  signal output network <== message[addressLength];
  // Check if the balance is over threshold
  signal input threshold;

  // TODO: check if the balance is over threshold
  // component lte = LessEqThan(2);
  // lte.in[0] <== threshold;
  // lte.in[1] <== balance;
  // Create nullifier
  signal input r2;
  signal input s2;
  signal input nonce;
  
  component nullifier = Nullify();
  nullifier.r <== r2;
  nullifier.s <== s2;
  nullifier.nonce <== nonce;
  
  signal output nullifierHash <== nullifier.nullifierHash;
}

component main{public [threshold, pubKeyX, balance]} = EthereumBalanceChecker();