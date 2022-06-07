pragma circom 2.0.4;

template ERC721OwnershipChecker() {
  // Message checking
  signal input message[90];
  signal input tokenAddress[42];
  for (var i = 0; i < 42; i++) {
    message[48 + i] === tokenAddress[i];
  }
  
  // EdDSA signature
  // TODO: check validity of EdDSA signature
  // signal input attestorPublicKey[32]; // TODO: figure out the size
  // signal input A[256];
  // signal input R8[256];
  // signal input S[256];
  // Result
  // signal output result;
  // result <== tokenAddress;


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
