pragma circom 2.0.4;

include "./helpers/Nullify.circom";
include "./helpers/EdDSAValidator.circom";

template EmailOwnershipChecker() {
  var domainLength = 90;
  // Get message
  signal input message[domainLength];
  // Output domain
  signal output domain[domainLength];
  
  for (var i = 0; i < domainLength; i++) {
    domain[i] <== message[i];
  }
  // Check if the EdDSA signature is valid
  signal input pubKeyX;
  signal input pubKeyY;
  signal input R8x;
  signal input R8y;
  signal input S;

  component edDSAValidator = EdDSAValidator(domainLength);
  edDSAValidator.pubKeyX <== pubKeyX;
  edDSAValidator.pubKeyY <== pubKeyY;
  edDSAValidator.R8x <== R8x;
  edDSAValidator.R8y <== R8y;
  edDSAValidator.S <== S;
  for (var i = 0; i < domainLength; i++) {
    edDSAValidator.message[i] <== message[i];
  }
  // Create nullifier
  signal input nonce[2];

  component nullifier = Nullify();
  nullifier.r <== nonce[0];
  nullifier.s <== nonce[1];
  
  signal output nullifierHash <== nullifier.nullifierHash;
}

component main{public [pubKeyX]} = EmailOwnershipChecker();
