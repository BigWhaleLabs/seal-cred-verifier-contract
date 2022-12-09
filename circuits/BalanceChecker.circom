pragma circom 2.0.4;

include "../node_modules/circomlib/circuits/mimcsponge.circom";
include "./templates/EdDSAValidator.circom";
include "./templates/MerkleTreeCheckerMiMC.circom";
include "./templates/SealHubValidator.circom";

// This circuit verifies two proofs:
// 1. The user knows precommitment to sealHubAddress on SealHub (proxy of Ethereum address ownership)
// 2. The sealHubAddress is a part of a specific balance attestation from SealCred attestor
template BalanceChecker() {
  var balanceMessageLength = 5;
  // Get balance attestation message
  signal input balanceMessage[balanceMessageLength];
  // Gather signals
  signal output attestationType <== balanceMessage[0];
  signal ownersMerkleRoot <== balanceMessage[1];
  signal output tokenAddress <== balanceMessage[2];
  signal output network <== balanceMessage[3];
  signal output threshold <== balanceMessage[4];
  // Check balance attestation validity
  signal input balancePubKeyX;
  signal input balancePubKeyY;
  signal input balanceR8x;
  signal input balanceR8y;
  signal input balanceS;

  component edDSAValidatorToken = EdDSAValidator(balanceMessageLength);
  edDSAValidatorToken.pubKeyX <== balancePubKeyX;
  edDSAValidatorToken.pubKeyY <== balancePubKeyY;
  edDSAValidatorToken.R8x <== balanceR8x;
  edDSAValidatorToken.R8y <== balanceR8y;
  edDSAValidatorToken.S <== balanceS;
  for (var i = 0; i < balanceMessageLength; i++) {
    edDSAValidatorToken.message[i] <== balanceMessage[i];
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
  nullifierMimc.ins[3 * k + 1] <== 110852321604106932801557041130035372901; // "SealCred Balance" in decimal
  // Export nullifier
  signal output nullifier <== nullifierMimc.outs[0];

  // Check Merkle proof
  var balanceAttestationDepth = 20;
  signal input ownersPathIndices[balanceAttestationDepth];
  signal input ownersSiblings[balanceAttestationDepth];
  component merkleTreeChecker = MerkleTreeCheckerMiMC(balanceAttestationDepth);
  merkleTreeChecker.leaf <== sealHubAddress;
  merkleTreeChecker.root <== ownersMerkleRoot;
  for (var i = 0; i < balanceAttestationDepth; i++) {
    merkleTreeChecker.pathElements[i] <== ownersSiblings[i];
    merkleTreeChecker.pathIndices[i] <== ownersPathIndices[i];
  }
}

component main{public [balancePubKeyX]} = BalanceChecker();