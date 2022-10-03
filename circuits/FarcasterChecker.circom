pragma circom 2.0.4;

include "./helpers/Nullify.circom";
include "./helpers/EdDSAValidator.circom";

template FarcasterChecker() {
  var farcasterWordLength = 9;
  var farcasterMessageLength = 2 + farcasterWordLength;
  // Get messages
  signal input farcasterMessage[farcasterMessageLength];
  signal input address;
  // Export attestation type
  signal output attestationType <== farcasterMessage[0];
  // Check if owner address is the same
  farcasterMessage[1] === address;
  // Export farcaster word
  signal output farcaster[farcasterWordLength];
  for (var i = 0; i < farcasterWordLength; i++) {
    farcaster[i] <== farcasterMessage[2 + i];
  }
  // Check if the EdDSA signature of farcaster is valid
  signal input farcasterPubKeyX;
  signal input farcasterPubKeyY;
  signal input farcasterR8x;
  signal input farcasterR8y;
  signal input farcasterS;

  component farcasterEdDSAValidator = EdDSAValidator(farcasterMessageLength);
  farcasterEdDSAValidator.pubKeyX <== farcasterPubKeyX;
  farcasterEdDSAValidator.pubKeyY <== farcasterPubKeyY;
  farcasterEdDSAValidator.R8x <== farcasterR8x;
  farcasterEdDSAValidator.R8y <== farcasterR8y;
  farcasterEdDSAValidator.S <== farcasterS;
  for (var i = 0; i < farcasterMessageLength; i++) {
    farcasterEdDSAValidator.message[i] <== farcasterMessage[i];
  }
  // Check if the EdDSA signature of address is valid
  signal input addressPubKeyX;
  signal input addressPubKeyY;
  signal input addressR8x;
  signal input addressR8y;
  signal input addressS;

  component edDSAValidatorAddress = EdDSAValidator(1);
  edDSAValidatorAddress.pubKeyX <== addressPubKeyX;
  edDSAValidatorAddress.pubKeyY <== addressPubKeyY;
  edDSAValidatorAddress.R8x <== addressR8x;
  edDSAValidatorAddress.R8y <== addressR8y;
  edDSAValidatorAddress.S <== addressS;
  edDSAValidatorAddress.message[0] <== address;
  // Check if attestors are the same
  farcasterPubKeyX === addressPubKeyX;
  // Create nullifier
  signal input nonce[2];
  
  component nullifier = Nullify();
  nullifier.r <== nonce[0];
  nullifier.s <== nonce[1];

  signal output nullifierHash <== nullifier.nullifierHash;
}

component main{public [farcasterPubKeyX]} = FarcasterChecker();