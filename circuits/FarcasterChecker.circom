pragma circom 2.0.4;

include "../node_modules/circomlib/circuits/mimcsponge.circom";
include "./templates/EdDSAValidator.circom";
include "./templates/MerkleTreeCheckerMiMC.circom";
include "./templates/SealHubValidator.circom";

template FarcasterChecker() {
  var farcasterWordLength = 9;
  var farcasterMessageLength = 2 + farcasterWordLength;
  // Get farcaster attestation message
  signal input farcasterMessage[farcasterMessageLength];
  signal output attestationType <== farcasterMessage[0];
  signal ownersMerkleRoot <== farcasterMessage[1];
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
  // Verify SealHub commitment
  var k = 4;
  var sealHubDepth = 30;
  signal input sealHubS[k];
  signal input sealHubU[2][k];
  signal input sealHubAddress;
  signal input sealHubPathIndices[sealHubDepth];
  signal input sealHubSiblings[sealHubDepth];

  component sealHubValidator = SealHubValidator();
  for (var i = 0; i < k; i++) {
    sealHubValidator.s[i] <== sealHubS[i];
    sealHubValidator.U[0][i] <== sealHubU[0][i];
    sealHubValidator.U[1][i] <== sealHubU[1][i];
  }
  sealHubValidator.address <== sealHubAddress;
  for (var i = 0; i < sealHubDepth; i++) {
    sealHubValidator.pathIndices[i] <== sealHubPathIndices[i];
    sealHubValidator.siblings[i] <== sealHubSiblings[i];
  }
  // Export Merkle root
  signal output sealHubMerkleRoot <== sealHubValidator.merkleRoot;

  // Compute nullifier
  component nullifierMimc = MiMCSponge(3 * k + 2, 220, 1);
  nullifierMimc.k <== 0;
  for (var i = 0; i < k; i++) {
    nullifierMimc.ins[i] <== sealHubS[i];
    nullifierMimc.ins[k + i] <== sealHubU[0][i];
    nullifierMimc.ins[2 * k + i] <== sealHubU[1][i];
  }
  nullifierMimc.ins[3 * k] <== sealHubAddress;
  nullifierMimc.ins[3 * k + 1] <== 7264817748646751948082916036165286355035506; // "SealCred Farcaster" in decimal
  // Export nullifier
  signal output nullifier <== nullifierMimc.outs[0];
  
  // Check Merkle proof
  var levels = 20;
  signal input ownersPathIndices[levels];
  signal input ownersSiblings[levels];

  component merkleTreeChecker = MerkleTreeCheckerMiMC(levels);
  merkleTreeChecker.leaf <== sealHubAddress;
  merkleTreeChecker.root <== ownersMerkleRoot;
  for (var i = 0; i < levels; i++) {
    merkleTreeChecker.pathElements[i] <== ownersSiblings[i];
    merkleTreeChecker.pathIndices[i] <== ownersPathIndices[i];
  }
}

component main{public [farcasterPubKeyX]} = FarcasterChecker();