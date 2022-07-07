pragma circom 2.0.4;

include "../node_modules/circomlib/circuits/mimc.circom";
include "../node_modules/circomlib/circuits/comparators.circom";
include "./helpers/Nullify.circom";
include "./helpers/EdDSAValidator.circom";

template BalanceChecker() {
  var addressLength = 42;
  var ownsWordLength = 4;
  var networkLength = 1;
  var messageTokenLength = addressLength + ownsWordLength + addressLength + networkLength;
  // Get messages
  signal input messageToken[messageTokenLength];
  signal input messageAddress[addressLength];
  // Check if token owner address is the same
  for (var i = 0; i < addressLength; i++) {
    messageToken[i] === messageAddress[i];
  }
  // Export token address
  var tokenAddressIndex = addressLength + ownsWordLength;
  
  signal output tokenAddress[addressLength];
  for (var i = 0; i < addressLength; i++) {
    tokenAddress[i] <== messageToken[tokenAddressIndex + i];
  }
  // Check if the EdDSA signature of token balance is valid
  signal input pubKeyXToken;
  signal input pubKeyYToken;
  signal input R8xToken;
  signal input R8yToken;
  signal input SToken;
  signal input MToken;
  signal input balance;

  component edDSAValidatorToken = EdDSAValidator(messageTokenLength + 1);
  edDSAValidatorToken.pubKeyX <== pubKeyXToken;
  edDSAValidatorToken.pubKeyY <== pubKeyYToken;
  edDSAValidatorToken.R8x <== R8xToken;
  edDSAValidatorToken.R8y <== R8yToken;
  edDSAValidatorToken.S <== SToken;
  edDSAValidatorToken.messageHash <== MToken;
  for (var i = 0; i < messageTokenLength; i++) {
    edDSAValidatorToken.message[i] <== messageToken[i];
  }
  edDSAValidatorToken.message[messageTokenLength] <== balance;
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
  signal output network <== messageToken[addressLength];
  // Check if the balance is over threshold
  signal input threshold;

  component lt = LessThan(252);
  lt.in[0] <== threshold;
  lt.in[1] <== balance + 1;
  lt.out === 1;
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

component main{public [threshold, pubKeyXToken]} = BalanceChecker();