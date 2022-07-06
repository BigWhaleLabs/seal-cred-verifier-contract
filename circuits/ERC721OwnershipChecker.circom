pragma circom 2.0.4;

include "../node_modules/circomlib/circuits/eddsamimc.circom";
include "../node_modules/circomlib/circuits/mimc.circom";
include "./Nullify.circom";

template ERC721OwnershipChecker() {
  var addressLength = 42;
  var ownsWordLength = 4;
  // Check if the original message ends with the token address
  var messageLength = addressLength + ownsWordLength + addressLength;
  signal input message[messageLength];
  signal input tokenAddress[addressLength];

  var tokenAddressIndex = addressLength + ownsWordLength;
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

component main{public [tokenAddress, pubKeyX]} = ERC721OwnershipChecker();
