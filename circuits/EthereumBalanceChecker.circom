pragma circom 2.0.4;

include "../node_modules/circomlib/circuits/eddsamimc.circom";
include "../node_modules/circomlib/circuits/mimc.circom";
include "./Nullify.circom";

template EthereumBalanceChecker() {
  
}

component main{public [tokenAddress, pubKeyX]} = EthereumBalanceChecker();