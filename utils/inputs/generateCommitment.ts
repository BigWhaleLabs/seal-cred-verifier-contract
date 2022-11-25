import { BigIntOrString, Input } from '../Input'
import { BigNumber } from 'ethers'
import Mimc7 from '../Mimc7'

export default async function generateCommitment(inputs: Input) {
  const k = 4
  const prepHash: BigIntOrString[] = []

  for (let i = 0; i < k; i++) {
    prepHash[i] = inputs.s[0][i]
    prepHash[k + i] = inputs.U[0][i]
    prepHash[2 * k + i] = inputs.U[1][i]
    prepHash[3 * k + i] = inputs.pubKey[0][i]
    prepHash[4 * k + i] = inputs.pubKey[1][i]
  }

  const mimc7 = await new Mimc7().prepare()
  const preCommitment = prepHash.flat().map((v) => BigInt(v))

  return BigNumber.from(mimc7.hash(preCommitment)).toBigInt()
}
