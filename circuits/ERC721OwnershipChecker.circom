pragma circom 2.0.4;

template ERC721OwnershipChecker() {
  // Message checking
  signal input message[90];
  signal input tokenAddress[42];
  for (var i = 0; i < 42; i++) {
    message[48 + i] === tokenAddress[i];
  }
  // Attestor address checking
  signal input attestorPublicKey;
  log(attestorPublicKey);
  // EdDSA signature
  // signal input attestorPublicKey[32]; // TODO: figure out the size
  // signal input A[256];
  // signal input R8[256];
  // signal input S[256];
  // Result
  // signal output result;
  // result <== tokenAddress;

  // TODO: check validity of EdDSA signature
  // TODO: check that EdDSA signature was signed by the public key of the attestor
  // TODO: write the result into the result signal

  // DEBUG (have to add it because we need at least 1 output)
  signal input a;
  signal input b;
  signal output c <== a * b;
}

component main{public [tokenAddress]} = ERC721OwnershipChecker();
