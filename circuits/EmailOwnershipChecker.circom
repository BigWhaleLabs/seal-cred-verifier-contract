pragma circom 2.0.4;

include "../node_modules/circomlib/circuits/eddsamimc.circom";
include "../node_modules/circomlib/circuits/bitify.circom";
include "../node_modules/circomlib/circuits/mimc.circom";

template EmailOwnershipChecker() {
  // Check if the original message contains the email domain
  signal input message[335];
  signal input domain[255];
  signal input domainIndex;
  for (var i = 0; i < 255; i++) {
    if (domain[i] != 0) {
      message[domainIndex + i] === domain[i];
    }
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
  component mimc7 = MultiMiMC7(335, 91);
  mimc7.k <== 0;
  for (var i = 0; i < 335; i++) {
    mimc7.in[i] <== message[i];
  }
  M === mimc7.out;

  // Export the nullifier
  component bits2Num = Bits2Num(14);
  for (var i = 0; i < 14; i++) {
    bits2Num.in[i] <== message[i];
  }
  signal output nullifier <== bits2Num.out;
}

component main{public [domain, pubKeyX]} = EmailOwnershipChecker();
