pragma circom 2.0.4;

include "../node_modules/circomlib/circuits/comparators.circom";
include "./helpers/Nullify.circom";
include "./helpers/MerkleTree.circom";
include "./helpers/eth.circom";
include "./helpers/EdDSAValidator.circom";

template BalanceChecker() {
  var levels = 20;
  var n = 3;
  var k = 86;
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
  // Check the Merkle root
  signal input pubkey[2][k];
  signal input pathElements[levels];
  signal input pathIndices[levels];
  signal input root;

  component flattenPub = FlattenPubkey(n, k);
  for (var i = 0; i < k; i++) {
    flattenPub.chunkedPubkey[0][i] <== pubkey[0][i];
    flattenPub.chunkedPubkey[1][i] <== pubkey[1][i];
  }

  component addressGen = PubkeyToAddress();
    for (var i = 0;i < 512;i++) addressGen.pubkeyBits[i] <== flattenPub.pubkeyBits[i];

  component addressMimc = MiMCSponge(1, 220, 1);
  addressMimc.ins[0] <== addressGen.address;
  addressMimc.k <== 123;

  component tree = MerkleTreeChecker(levels);
    tree.leaf <== addressMimc.outs[0];
    tree.root <== root;
    for (var i = 0; i < levels; i++) {
        tree.pathElements[i] <== pathElements[i];
        tree.pathIndices[i] <== pathIndices[i];
    }
  // Get the network
  signal output network <== messageToken[messageTokenLength - 1];
  // Check if the balance is over threshold
  signal input threshold;

  component lt = LessThan(252);
  lt.in[0] <== threshold;
  lt.in[1] <== balance + 1;
  lt.out === 1;
  // Create nullifier
  signal input r2;
  signal input s2;
  
  component nullifier = Nullify();
  nullifier.r <== r2;
  nullifier.s <== s2;

  signal output nullifierHash <== nullifier.nullifierHash;
}

component main{public [threshold, pubKeyXToken]} = BalanceChecker();