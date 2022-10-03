pragma circom 2.0.4;

include "../node_modules/circomlib/circuits/comparators.circom";
include "./helpers/Nullify.circom";
include "./helpers/EdDSAValidator.circom";

template BalanceChecker() {
  var addressLength = 42;
  var ownsWordLength = 4;
  var networkLength = 1;
  var messageTokenLength = ownsWordLength + addressLength + networkLength;
  // Get messages
  signal input messageToken[messageTokenLength];
  signal input messageAddress[addressLength];
  // Export token address  
  signal output tokenAddress[addressLength];
  for (var i = 0; i < addressLength; i++) {
    tokenAddress[i] <== messageToken[ownsWordLength + i];
  }
  // Check if the EdDSA signature of token balance is valid
  signal input pubKeyXToken;
  signal input pubKeyYToken;
  signal input R8xToken;
  signal input R8yToken;
  signal input SToken;
  signal input MToken;
  signal input ownersMerkleRoot;
  signal input threshold;

  component edDSAValidatorToken = EdDSAValidator(messageTokenLength + 2);
  edDSAValidatorToken.pubKeyX <== pubKeyXToken;
  edDSAValidatorToken.pubKeyY <== pubKeyYToken;
  edDSAValidatorToken.R8x <== R8xToken;
  edDSAValidatorToken.R8y <== R8yToken;
  edDSAValidatorToken.S <== SToken;
  edDSAValidatorToken.messageHash <== MToken;
  for (var i = 0; i < messageTokenLength; i++) {
    edDSAValidatorToken.message[i] <== messageToken[i];
  }
  edDSAValidatorToken.message[messageTokenLength] <== ownersMerkleRoot;
  edDSAValidatorToken.message[messageTokenLength + 1] <== threshold;
  // Check if the EdDSA signature of address is valid
  signal input pubKeyXAddress;
  signal input pubKeyYAddress;
  signal input R8xAddress;
  signal input R8yAddress;
  signal input SAddress;
  signal input MAddress;

  component edDSAValidatorAddress = EdDSAValidator(addressLength);
  edDSAValidatorAddress.pubKeyX <== pubKeyXAddress;
  edDSAValidatorAddress.pubKeyY <== pubKeyYAddress;
  edDSAValidatorAddress.R8x <== R8xAddress;
  edDSAValidatorAddress.R8y <== R8yAddress;
  edDSAValidatorAddress.S <== SAddress;
  edDSAValidatorAddress.messageHash <== MAddress;
  for (var i = 0; i < addressLength; i++) {
    edDSAValidatorAddress.message[i] <== messageAddress[i];
  }
  // Check if attestors are the same
  pubKeyXToken === pubKeyXAddress;
  // Get the network
  signal output network <== messageToken[messageTokenLength - 1];
  // Create nullifier
  signal input r2;
  signal input s2;
  
  component nullifier = Nullify();
  nullifier.r <== r2;
  nullifier.s <== s2;

  signal output nullifierHash <== nullifier.nullifierHash;
  // Check Merkle proof
  var levels = 20;
  signal input pathIndices[levels];
  signal input siblings[levels];
}

component main{public [threshold, pubKeyXToken]} = BalanceChecker();