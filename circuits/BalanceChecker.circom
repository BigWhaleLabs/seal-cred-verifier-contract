pragma circom 2.0.4;

include "../node_modules/@big-whale-labs/seal-hub-verifier-template/circomlib/circuits/comparators.circom";
include "./helpers/Nullify.circom";
include "./helpers/EdDSAValidator.circom";
include "./helpers/MerkleTreeCheckerMiMC.circom";
include "../node_modules/@big-whale-labs/seal-hub-verifier-template/circuits/templates/SealHubValidator.circom";
include "../node_modules/@big-whale-labs/seal-hub-verifier-template/circuits/templates/PublicKeyChunksToNum.circom";
include "../efficient-zk-sig/zk-identity/eth.circom";

template BalanceChecker() {
  var balanceMessageLength = 5;
  // Get messages
  signal input balanceMessage[balanceMessageLength];
  signal input address;
  // Gather signals
  signal output attestationType <== balanceMessage[0];
  signal ownersMerkleRoot <== balanceMessage[1];
  signal output tokenAddress <== balanceMessage[2];
  signal output network <== balanceMessage[3];
  signal output threshold <== balanceMessage[4];
  // Check if the EdDSA signature of token balance is valid
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
  var k = 4;
  var levels = 30;
  // Get inputs, *never* export them publicly
  signal input r[k]; // Pre-commitment signature
  signal input s[k]; // Pre-commitment signature
  signal input U[2][k]; // Pre-commitment signature
  signal input pubKey[2][k]; // Pre-commitment public key
  signal input pathIndices[levels]; // Merkle proof that commitment is a part of the Merkle tree
  signal input siblings[levels]; // Merkle proof that commitment is a part of the Merkle tree
  // Verify SealHub commitment
  component sealHubValidator = SealHubValidator();
  for (var i = 0; i < k; i++) {
    sealHubValidator.s[i] <== s[i];
    sealHubValidator.U[0][i] <== U[0][i];
    sealHubValidator.U[1][i] <== U[1][i];
    sealHubValidator.pubKey[0][i] <== pubKey[0][i];
    sealHubValidator.pubKey[1][i] <== pubKey[1][i];
  }
  for (var i = 0; i < levels; i++) {
    sealHubValidator.pathIndices[i] <== pathIndices[i];
    sealHubValidator.siblings[i] <== siblings[i];
  }
  // Export Merkle root
  signal output merkleRoot <== sealHubValidator.merkleRoot;

  // Compute nullifier
  component mimc = MiMCSponge(2 * k + 2, 220, 1);
  for (var i = 0; i < k; i++) {
    mimc.ins[i] <== r[i];
    mimc.ins[i + k] <== s[i];
  }
  mimc.ins[2 * k] <== 420;
  mimc.ins[2 * k + 1] <== 69;
  mimc.k <== 0;
  // Export nullifier
  signal output nullifierHash <== mimc.outs[0];

  component flattenPub = FlattenPubkey(64, k);
  for (var i = 0; i < k; i++) {
    flattenPub.chunkedPubkey[0][i] <== pubKey[0][i];
    flattenPub.chunkedPubkey[1][i] <== pubKey[1][i];
  }

  component pubToAddr = PubkeyToAddress();
  for (var i = 0; i < 512; i++) {
    pubToAddr.pubkeyBits[i] <== flattenPub.pubkeyBits[i];
  }
  // Check Merkle proof
  var ownersLevels = 20;
  signal input ownersPathIndices[ownersLevels];
  signal input ownersSiblings[ownersLevels];
  component merkleTreeChecker = MerkleTreeCheckerMiMC(ownersLevels);
  merkleTreeChecker.leaf <== address;
  merkleTreeChecker.root <== ownersMerkleRoot;
  for (var i = 0; i < ownersLevels; i++) {
    merkleTreeChecker.pathElements[i] <== ownersSiblings[i];
    merkleTreeChecker.pathIndices[i] <== ownersPathIndices[i];
  }
}

component main{public [balancePubKeyX]} = BalanceChecker();