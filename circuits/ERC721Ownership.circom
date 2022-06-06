pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mux1.circom";

include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/multiplexer.circom";

include "../ecdsa-circuits/bigint.circom";
include "../ecdsa-circuits/secp256k1.circom";
include "../ecdsa-circuits/bigint_func.circom";
include "../ecdsa-circuits/ecdsa.circom";
include "../ecdsa-circuits/ecdsa_func.circom";
include "../ecdsa-circuits/secp256k1_func.circom";

template MerkleTreeChecker(nLevels, n, k) {
    assert(k >= 2);
    assert(k <= 100);

    signal input root;
    signal input leaf;
    signal input pathIndices[nLevels];
    signal input siblings[nLevels];

    signal input r[k];
    signal input s[k];
    signal input msghash[k];
    signal input pubkey[2][k];

    signal output result;

    component poseidons[nLevels];
    component mux[nLevels];

    signal hashes[nLevels + 1];
    hashes[0] <== leaf;

    for (var i = 0; i < nLevels; i++) {
        pathIndices[i] * (1 - pathIndices[i]) === 0;

        poseidons[i] = Poseidon(2);
        mux[i] = MultiMux1(2);

        mux[i].c[0][0] <== hashes[i];
        mux[i].c[0][1] <== siblings[i];

        mux[i].c[1][0] <== siblings[i];
        mux[i].c[1][1] <== hashes[i];

        mux[i].s <== pathIndices[i];

        poseidons[i].inputs[0] <== mux[i].out[0];
        poseidons[i].inputs[1] <== mux[i].out[1];

        hashes[i + 1] <== poseidons[i].out;
    }

    root === hashes[nLevels];

    var p[100] = get_secp256k1_prime(n, k);
    var order[100] = get_secp256k1_order(n, k);

    var sinv_comp[100] = mod_inv(n, k, s, order);
    signal sinv[k];
    component sinv_range_checks[k];
    for (var idx = 0; idx < k; idx++) {
        sinv[idx] <-- sinv_comp[idx];
        sinv_range_checks[idx] = Num2Bits(n);
        sinv_range_checks[idx].in <== sinv[idx];
    }
    component sinv_check = BigMultModP(n, k);
    for (var idx = 0; idx < k; idx++) {
        sinv_check.a[idx] <== sinv[idx];
        sinv_check.b[idx] <== s[idx];
        sinv_check.p[idx] <== order[idx];
    }
    for (var idx = 0; idx < k; idx++) {
        if (idx > 0) {
            sinv_check.out[idx] === 0;
        }
        if (idx == 0) {
            sinv_check.out[idx] === 1;
        }
    }

    // compute (h * sinv) mod n
    component g_coeff = BigMultModP(n, k);
    for (var idx = 0; idx < k; idx++) {
        g_coeff.a[idx] <== sinv[idx];
        g_coeff.b[idx] <== msghash[idx];
        g_coeff.p[idx] <== order[idx];
    }

    // compute (h * sinv) * G
    component g_mult = ECDSAPrivToPub(n, k);
    for (var idx = 0; idx < k; idx++) {
        g_mult.privkey[idx] <== g_coeff.out[idx];
    }

    // compute (r * sinv) mod n
    component pubkey_coeff = BigMultModP(n, k);
    for (var idx = 0; idx < k; idx++) {
        pubkey_coeff.a[idx] <== sinv[idx];
        pubkey_coeff.b[idx] <== r[idx];
        pubkey_coeff.p[idx] <== order[idx];
    }

    // compute (r * sinv) * pubkey
    component pubkey_mult = Secp256k1ScalarMult(n, k);
    for (var idx = 0; idx < k; idx++) {
        pubkey_mult.scalar[idx] <== pubkey_coeff.out[idx];
        pubkey_mult.point[0][idx] <== pubkey[0][idx];
        pubkey_mult.point[1][idx] <== pubkey[1][idx];
    }

    // compute (h * sinv) * G + (r * sinv) * pubkey
    component sum_res = Secp256k1AddUnequal(n, k);
    for (var idx = 0; idx < k; idx++) {
        sum_res.a[0][idx] <== g_mult.pubkey[0][idx];
        sum_res.a[1][idx] <== g_mult.pubkey[1][idx];
        sum_res.b[0][idx] <== pubkey_mult.out[0][idx];
        sum_res.b[1][idx] <== pubkey_mult.out[1][idx];
    }

    // compare sum_res.x with r
    component compare[k];
    signal num_equal[k - 1];
    for (var idx = 0; idx < k; idx++) {
        compare[idx] = IsEqual();
        compare[idx].in[0] <== r[idx];
        compare[idx].in[1] <== sum_res.out[0][idx];

        if (idx > 0) {
            if (idx == 1) {
                num_equal[idx - 1] <== compare[0].out + compare[1].out;
            } else {
                num_equal[idx - 1] <== num_equal[idx - 2] + compare[idx].out;
            }
        }
    }
    component res_comp = IsEqual();
    res_comp.in[0] <== k;
    res_comp.in[1] <== num_equal[k - 2];
    result <== res_comp.out;
}

component main{public [root]} = MerkleTreeChecker(20, 86, 3);
