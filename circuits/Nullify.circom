pragma circom 2.0.4;

include "../node_modules/circomlib/circuits/mimcsponge.circom";

template Nullify(k) {
    signal input r[k];
    signal input s[k];
    signal input nonce;
    signal output nullifierHash;

    component mimc = MiMCSponge(2 * k + 1, 220, 1);
    for (var i = 0; i < 3; i++) mimc.ins[i] <== r[i];
    for (var i = 3; i < 6; i++) mimc.ins[i] <== s[i-3];
    mimc.ins[6] <== nonce;
    mimc.k <== 123;

    nullifierHash <== mimc.outs[0];
}