import { utils } from 'ethers'
import entropy from './entropy'
import randomWallet from './randomWallet'

export default async function (message = 'For SealCred') {
  const signature = await randomWallet.signMessage(message)
  const { r: r2, s: s2 } = utils.splitSignature(signature)
  return { r2, s2, nonce: `0x${entropy.string()}` }
}
