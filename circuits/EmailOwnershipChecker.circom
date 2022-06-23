pragma circom 2.0.4;

include "../node_modules/circomlib/circuits/eddsamimc.circom";
include "../node_modules/circomlib/circuits/mimc.circom";
include "../node_modules/circomlib/circuits/comparators.circom";

template EmailOwnershipChecker() {
  var domainLength = 90;
  var nullifierLength = 14;
  var messageLength = domainLength + nullifierLength;
  // Check if the original message contains the email domain
  signal input message[messageLength];
  signal input domain[domainLength];
  for (var i = 0; i < domainLength; i++) {
    message[i] === domain[i];
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
  for (var i = 0; i < nullifierLength; i++) {
    nullifier[i] <== message[domainLength + i];
  }
}

component main{public [domain, pubKeyX]} = EmailOwnershipChecker();
