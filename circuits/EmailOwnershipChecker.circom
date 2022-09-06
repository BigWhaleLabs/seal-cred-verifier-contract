pragma circom 2.0.4;

include "./helpers/Nullify.circom";
include "./helpers/EdDSAValidator.circom";

template EmailOwnershipChecker() {
  var domainLength = 90;
  var messageLength = 90;
  // Get message
  signal input message[messageLength];
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
  signal input M;

  component edDSAValidator = EdDSAValidator(messageLength);
  edDSAValidator.pubKeyX <== pubKeyX;
  edDSAValidator.pubKeyY <== pubKeyY;
  edDSAValidator.R8x <== R8x;
  edDSAValidator.R8y <== R8y;
  edDSAValidator.S <== S;
  edDSAValidator.messageHash <== M;
  for (var i = 0; i < messageLength; i++) {
    edDSAValidator.message[i] <== message[i];
  }
  // Create nullifier
  signal input r2;
  signal input s2;

  component nullifier = Nullify();
  nullifier.r <== r2;
  nullifier.s <== s2;
  
  signal output nullifierHash <== nullifier.nullifierHash;
}

component main{public [pubKeyX]} = EmailOwnershipChecker();
