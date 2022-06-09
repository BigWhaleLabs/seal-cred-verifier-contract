pragma circom 2.0.4;

include "eddsamimc.circom";

template ERC721OwnershipChecker() {
  // Message checking
  signal input message[90];
  signal input tokenAddress[42];
  for (var i = 0; i < 42; i++) {
    message[48 + i] === tokenAddress[i];
  }

  // EdDSA signature
  signal input from_x;
  signal input from_y;
  signal input R8x;
  signal input R8y;
  signal input S;
  signal input M;
  component verifier = EdDSAMiMCVerifier();
  verifier.enabled <== 1;
  verifier.Ax <== from_x;
  verifier.Ay <== from_y;
  verifier.R8x <== R8x;
  verifier.R8y <== R8y;
  verifier.S <== S;
  verifier.M <== M;

  // Message hash checking
  // TODO: check that mimc7(message) is the same as M

  // Attestor address checking
  // TODO: check that EdDSA signature was signed by the public key of the attestor
  signal input attestorPublicKey;
  log(attestorPublicKey);

  // Result
  // TODO: write the result into the result signal
  signal output result;

  // DEBUG (have to add it because we need at least 1 output)
  signal input a;
  signal input b;
  signal output c <== a * b;
}

component main{public [tokenAddress]} = ERC721OwnershipChecker();
