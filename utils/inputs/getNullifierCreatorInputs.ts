import { BigNumber, utils } from 'ethers'
import {
  getCommitmentFromSignature,
  getMessageForAddress,
  getSealHubValidatorInputs,
} from '@big-whale-labs/seal-hub-kit'
import wallet from '../wallet'

const ninetyNineCommitments = Array(99)
  .fill(undefined)
  .map(() => BigNumber.from(utils.randomBytes(32)).toBigInt())

export default async function (commitments = ninetyNineCommitments) {
  const message = getMessageForAddress(wallet.address)
  const signature = await wallet.signMessage(message)
  const commitment = await getCommitmentFromSignature(signature, message)
  const sealHubValidatorInputs = await getSealHubValidatorInputs(
    signature,
    message,
    undefined,
    [...commitments, commitment]
  )
  return {
    pathIndices: sealHubValidatorInputs.pathIndices,
    siblings: sealHubValidatorInputs.siblings,
    U: sealHubValidatorInputs.U,
    s: sealHubValidatorInputs.s,
    address: sealHubValidatorInputs.address,
  }
}
