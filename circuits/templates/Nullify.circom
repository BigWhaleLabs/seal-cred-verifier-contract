pragma circom 2.0.4;

include "../../node_modules/circomlib/circuits/mimcsponge.circom";

template Nullify() {
    signal input r;
    signal input s;

    component mimc = MiMCSponge(2, 220, 1);
    mimc.ins[0] <== r;
    mimc.ins[1] <== s;
    mimc.k <== 0;

    signal output nullifierHash <== mimc.outs[0];
}