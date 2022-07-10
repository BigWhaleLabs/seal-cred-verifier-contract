import { utils } from 'ethers'
import entropy from './entropy'
import randomWallet from './randomWallet'

export default async function (
  message = `For SealCred\nnonce: 0x${entropy.string()}`
) {
  const signature = await randomWallet.signMessage(message)
  const { r: r2, s: s2 } = utils.splitSignature(signature)
  return { r2, s2 }
}
