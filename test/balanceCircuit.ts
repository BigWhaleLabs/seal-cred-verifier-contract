import { BigNumber, utils } from 'ethers'
import { expect } from 'chai'
import {
  getCommitmentFromPrecommitment,
  getMerkleTreeProof,
  getMessageForAddress,
  getUAndSFromSignature,
} from '@big-whale-labs/seal-hub-kit'
import { wasm as wasmTester } from 'circom_tester'
import getBalanceInputs from '../utils/inputs/getBalanceInputs'
import getNullifier from '../utils/inputs/getNullifier'
import getNullifierCreatorInputs from '../utils/inputs/getNullifierCreatorInputs'
import wallet from '../utils/wallet'

describe('BalanceChecker circuit', function () {
  before(async function () {
    this.circuit = await wasmTester('circuits/BalanceChecker.circom')
    this.baseInputs = await getBalanceInputs()
    const message = getMessageForAddress(wallet.address)
    const signature = await wallet.signMessage(message)

    const { U, s } = getUAndSFromSignature(signature, message)
    const address = utils.verifyMessage(message, signature)
    this.commitment = await getCommitmentFromPrecommitment({ U, s, address })
    ;(this.commitments = Array(99)
      .fill(undefined)
      .map(() => BigNumber.from(utils.randomBytes(32)).toBigInt())),
      Object.assign(
        (this.baseInputs, await getNullifierCreatorInputs(this.commitments))
      )
    this.treeProof = await getMerkleTreeProof(this.commitment, [
      ...this.commitments,
      this.commitment,
    ])
  })

  it.only('should generate the witness successfully', async function () {
    const witness = await this.circuit.calculateWitness(this.baseInputs)
    const nullifier = await getNullifier(this.baseInputs)
    await this.circuit.assertOut(witness, {})
    expect(witness[6]).to.eq(this.treeProof.root)
    expect(witness[7]).to.eq(nullifier)
  })
  // it('should return the correct network byte for mainnet', async function () {
  //   const inputs = await getBalanceInputs(
  //     undefined,
  //     undefined,
  //     undefined,
  //     undefined,
  //     undefined,
  //     'm'
  //   )
  //   const witness = await this.circuit.calculateWitness(inputs)
  //   await this.circuit.assertOut(witness, {})
  //   expect(witness[4]).to.be.deep.equal(BigNumber.from(0x6d))
  // })
  // it('should return the correct network byte for goerli', async function () {
  //   const inputs = await getBalanceInputs(
  //     undefined,
  //     undefined,
  //     undefined,
  //     undefined,
  //     undefined,
  //     'g'
  //   )
  //   const witness = await this.circuit.calculateWitness(inputs)
  //   await this.circuit.assertOut(witness, {})
  //   expect(witness[4]).to.be.deep.equal(BigNumber.from(0x67))
  // })
})
