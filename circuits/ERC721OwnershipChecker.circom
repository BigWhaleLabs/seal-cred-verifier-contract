pragma circom 2.0.4;

include "../node_modules/circomlib/circuits/eddsamimc.circom";
include "../node_modules/circomlib/circuits/mimc.circom";

template ERC721OwnershipChecker() {
  var nullifierLength = 14;
  var addressLength = 42;
  var ownsWordLength = 4;
  var dashLength = 1;
  // Check if the original message ends with the token address
  var messageLength = addressLength + dashLength + ownsWordLength + dashLength + addressLength + dashLength + nullifierLength;
  signal input message[messageLength];
  signal input tokenAddress[addressLength];
  var tokenAddressIndex = addressLength + dashLength + ownsWordLength + dashLength;
  for (var i = 0; i < addressLength; i++) {
    message[tokenAddressIndex + i] === tokenAddress[i];
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
  component mimc7 = MultiMiMC7(messageLength, 91);
  mimc7.k <== 0;
  for (var i = 0; i < messageLength; i++) {
    mimc7.in[i] <== message[i];
  }
  M === mimc7.out;
  // Export the nullifier
  signal output nullifier[nullifierLength];
  var nullifierIndex = addressLength + dashLength + ownsWordLength + dashLength + addressLength + dashLength;
  for (var i = 0; i < nullifierLength; i++) {
    nullifier[i] <== message[nullifierIndex + i];
  }
}

component main{public [tokenAddress, pubKeyX]} = ERC721OwnershipChecker();
