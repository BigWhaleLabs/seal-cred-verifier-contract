pragma circom 2.0.4;

include "../circomlib/circuits/eddsamimc.circom";
include "../circomlib/circuits/bitify.circom";
include "../circomlib/circuits/mimc.circom";

template ERC721OwnershipChecker() {
  // Check if the original message ends with the token address
  signal input message[90];
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

  // Check if the EdDSA' "M" is "message" hashed
  // TODO: check that mimc7(message) is the same as M
}

component main{public [tokenAddress, pubKeyX]} = ERC721OwnershipChecker();
