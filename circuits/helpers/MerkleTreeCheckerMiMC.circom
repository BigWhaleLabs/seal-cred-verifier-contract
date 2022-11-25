pragma circom 2.0.4;

include "../../node_modules/circomlib/circuits/mimc.circom";

// Computes MiMC([left, right])
template HashLeftRightMiMC() {
  signal input left;
  signal input right;

  component mimc7 = MultiMiMC7(2, 91);
  mimc7.k <== 0;
  mimc7.in[0] <== left;
  mimc7.in[1] <== right;

  signal output hash <== mimc7.out;
}

// if s == 0 returns [in[0], in[1]]
// if s == 1 returns [in[1], in[0]]
template DualMuxMiMC() {
  signal input in[2];
  signal input s;
  signal output out[2];
  s * (1 - s) === 0;
  out[0] <== (in[1] - in[0])*s + in[0];
  out[1] <== (in[0] - in[1])*s + in[1];
}

// Verifies that merkle proof is correct for given merkle root and a leaf
// pathIndices input is an array of 0/1 selectors telling whether given pathElement is on the left or right side of merkle path
template MerkleTreeCheckerMiMC(levels) {
  signal input leaf;
  signal input root;
  signal input pathElements[levels];
  signal input pathIndices[levels];

  component selectors[levels];
  component hashers[levels];

  for (var i = 0; i < levels; i++) {
    selectors[i] = DualMuxMiMC();
    selectors[i].in[0] <== i == 0 ? leaf : hashers[i - 1].hash;
    selectors[i].in[1] <== pathElements[i];
    selectors[i].s <== pathIndices[i];

    hashers[i] = HashLeftRightMiMC();
    hashers[i].left <== selectors[i].out[0];
    hashers[i].right <== selectors[i].out[1];
  }
  
  root === hashers[levels - 1].hash;
}