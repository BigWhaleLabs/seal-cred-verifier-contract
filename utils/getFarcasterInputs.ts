import { buildBabyjub, buildMimc7 } from 'circomlibjs'
import { utils } from 'ethers'
import eddsaSign from './eddsaSign'
import getSignatureInputs from './getSignatureInputs'

async function inputsForMessage(message: string, suffix: string) {
  const babyJub = await buildBabyjub()
  const F = babyJub.F
  const messageBytes = utils.toUtf8Bytes(message)
  const mimc7 = await buildMimc7()
  const M = mimc7.multiHash(messageBytes)
  const { publicKey, signature } = await eddsaSign(M)
  return {
    [`message${suffix}`]: Array.from(messageBytes),
    [`pubKeyX${suffix}`]: F.toObject(publicKey[0]).toString(),
    [`pubKeyY${suffix}`]: F.toObject(publicKey[1]).toString(),
    [`R8x${suffix}`]: F.toObject(signature.R8[0]).toString(),
    [`R8y${suffix}`]: F.toObject(signature.R8[1]).toString(),
    [`S${suffix}`]: signature.S.toString(),
    [`M${suffix}`]: F.toObject(M).toString(),
  }
}

export default async function (
  ownerAddress = '0xbf74483DB914192bb0a9577f3d8Fb29a6d4c08eE'
) {
  return {
    ...(await inputsForMessage(ownerAddress, 'Address')),
    ...(await inputsForMessage(`${ownerAddress}ownsfarcaster`, 'Farcaster')),
    ...(await getSignatureInputs()),
  }
}
