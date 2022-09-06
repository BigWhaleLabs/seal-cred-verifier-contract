pragma circom 2.0.4;

include "./helpers/Nullify.circom";
include "./helpers/EdDSAValidator.circom";

template FarcasterChecker() {
  var addressLength = 42;
  var ownsWordLength = 4;
  var farcasterWordLength = 9;
  var messageFarcasterLength = addressLength + ownsWordLength + farcasterWordLength;
  // Get messages
  signal input messageFarcaster[messageFarcasterLength];
  signal input messageAddress[addressLength];
  // Check if owner address is the same
  for (var i = 0; i < addressLength; i++) {
    messageFarcaster[i] === messageAddress[i];
  }
  // Export farcaster word
  var farcasterIndex = addressLength + ownsWordLength;
  
  signal output farcaster[farcasterWordLength];
  for (var i = 0; i < farcasterIndex; i++) {
    farcaster[i] <== messageFarcaster[farcasterIndex + i];
  }
  // Check if the EdDSA signature of farcaster is valid
  signal input pubKeyXFarcaster;
  signal input pubKeyYFarcaster;
  signal input R8xFarcaster;
  signal input R8yFarcaster;
  signal input SFarcaster;
  signal input MFarcaster;

  component edDSAValidatorFarcaster = EdDSAValidator(messageFarcasterLength);
  edDSAValidatorFarcaster.pubKeyX <== pubKeyXFarcaster;
  edDSAValidatorFarcaster.pubKeyY <== pubKeyYFarcaster;
  edDSAValidatorFarcaster.R8x <== R8xFarcaster;
  edDSAValidatorFarcaster.R8y <== R8yFarcaster;
  edDSAValidatorFarcaster.S <== SFarcaster;
  edDSAValidatorFarcaster.messageHash <== MFarcaster;
  for (var i = 0; i < messageFarcasterLength; i++) {
    edDSAValidatorFarcaster.message[i] <== messageFarcaster[i];
  }
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
  pubKeyXFarcaster === pubKeyXAddress;
  // Create nullifier
  signal input r2;
  signal input s2;
  
  component nullifier = Nullify();
  nullifier.r <== r2;
  nullifier.s <== s2;

  signal output nullifierHash <== nullifier.nullifierHash;
}

component main{public [pubKeyXFarcaster]} = BalanceChecker();