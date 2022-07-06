pragma circom 2.0.4;

include "../node_modules/circomlib/circuits/mimcsponge.circom";

template Nullify() {
    signal input r;
    signal input s;
    signal input nonce;
    signal output nullifierHash;

    component mimc = MiMCSponge(3, 220, 1);
    mimc.ins[0] <== r;
    mimc.ins[1] <== s;
    mimc.ins[2] <== nonce;
    mimc.k <== 0;

    nullifierHash <== mimc.outs[0];
}