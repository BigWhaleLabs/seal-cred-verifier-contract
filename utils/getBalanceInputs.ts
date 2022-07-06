import { buildBabyjub, buildMimc7 } from 'circomlibjs'
import { utils } from 'ethers'
import eddsaSign from './eddsaSign'
import getSignatureInputs from './getSignatureInputs'

export default async function (
  balance = '0x6b87c4e204970e6',
  threshold = '0x1',
  ownerAddress = '0xbf74483DB914192bb0a9577f3d8Fb29a6d4c08eE',
  tokenAddress = '0x722B0676F457aFe13e479eB2a8A4De88BA15B2c6'
) {
  // Message
  const message = `${ownerAddress}owns${tokenAddress}g`
  const messageUInt8 = utils.toUtf8Bytes(message)
  const mimc7 = await buildMimc7()
  const M = mimc7.multiHash([...messageUInt8, balance])
  // EdDSA
  const { publicKey, signature } = await eddsaSign(M)
  // Generating inputs
  const babyJub = await buildBabyjub()
  const F = babyJub.F
  return {
    message: Array.from(messageUInt8),
    balance,
    threshold,
    pubKeyX: F.toObject(publicKey[0]).toString(),
    pubKeyY: F.toObject(publicKey[1]).toString(),
    R8x: F.toObject(signature.R8[0]).toString(),
    R8y: F.toObject(signature.R8[1]).toString(),
    S: signature.S.toString(),
    M: F.toObject(M).toString(),
    ...(await getSignatureInputs()),
  }
}
