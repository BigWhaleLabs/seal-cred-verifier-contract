pragma circom 2.0.4;

include "../node_modules/circomlib/circuits/mimc.circom";
include "../node_modules/circomlib/circuits/comparators.circom";
include "./helpers/Nullify.circom";
include "./helpers/EdDSAValidator.circom";

template BalanceChecker() {
  var addressLength = 42;
  var ownsWordLength = 4;
  var networkLength = 1;
  var messageLength = addressLength + ownsWordLength + addressLength + networkLength;
  // Export token address
  var tokenAddressIndex = addressLength + ownsWordLength;
  signal input message[messageLength];
  
  signal output tokenAddress[addressLength];
  for (var i = 0; i < addressLength; i++) {
    tokenAddress[i] <== message[tokenAddressIndex + i];
  }
  // Check if the EdDSA signature is valid
  signal input pubKeyX;
  signal input pubKeyY;
  signal input R8x;
  signal input R8y;
  signal input S;
  signal input M;
  signal input balance;

  component edDSAValidator = EdDSAValidator(messageLength + 1);
  edDSAValidator.pubKeyX <== pubKeyX;
  edDSAValidator.pubKeyY <== pubKeyY;
  edDSAValidator.R8x <== R8x;
  edDSAValidator.R8y <== R8y;
  edDSAValidator.S <== S;
  edDSAValidator.messageHash <== M;
  for (var i = 0; i < messageLength; i++) {
    edDSAValidator.message[i] <== message[i];
  }
  edDSAValidator.message[messageLength] <== balance;
  // Get the network
  signal output network <== message[addressLength];
  // Check if the balance is over threshold
  signal input threshold;

  component lt = LessThan(252);
  lt.in[0] <== threshold;
  lt.in[1] <== balance + 1;
  lt.out === 1;
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

component main{public [threshold, pubKeyX]} = BalanceChecker();