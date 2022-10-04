import { buildBabyjub, buildMimc7 } from 'circomlibjs'
import { utils } from 'ethers'
import eddsaSign from '../eddsa/eddsaSign'
import getAddressSignatureInputs from './getAddressSignatureInputs'
import getNonceInputs from './getNonceInputs'

async function getFarcasterSignatureInputs(ownerAddress: string) {
  const babyJub = await buildBabyjub()
  const F = babyJub.F
  const farcasterBytes = utils.toUtf8Bytes('farcaster')
  const message = [
    0, // "owns" type of attestation
    ownerAddress,
    ...farcasterBytes,
  ]
  const mimc7 = await buildMimc7()
  const hash = mimc7.multiHash(message)
  const { publicKey, signature } = await eddsaSign(hash)
  return {
    farcasterMessage: message,
    farcasterPubKeyX: F.toObject(publicKey[0]).toString(),
    farcasterPubKeyY: F.toObject(publicKey[1]).toString(),
    farcasterR8x: F.toObject(signature.R8[0]).toString(),
    farcasterR8y: F.toObject(signature.R8[1]).toString(),
    farcasterS: signature.S.toString(),
  }
}

export default async function (
  ownerAddress = '0xbf74483DB914192bb0a9577f3d8Fb29a6d4c08eE'
) {
  return {
    ...(await getAddressSignatureInputs(ownerAddress)),
    ...(await getFarcasterSignatureInputs(ownerAddress)),
    nonce: getNonceInputs(),
  }
}
