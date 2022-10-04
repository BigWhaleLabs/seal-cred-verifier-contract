import { utils } from 'ethers'
import Mimc7 from '../Mimc7'
import eddsaSign from '../eddsa/eddsaSign'
import getAddressSignatureInputs from './getAddressSignatureInputs'
import getNonceInputs from './getNonceInputs'

async function getFarcasterSignatureInputs(ownerAddress: string) {
  const farcasterBytes = utils.toUtf8Bytes('farcaster')
  const message = [
    0, // "owns" type of attestation
    ownerAddress,
    ...farcasterBytes,
  ]
  const mimc7 = await new Mimc7().prepare()
  const hash = mimc7.hashWithoutBabyJub(message)
  const { publicKey, signature } = await eddsaSign(hash)
  return {
    farcasterMessage: message,
    farcasterPubKeyX: mimc7.F.toObject(publicKey[0]).toString(),
    farcasterPubKeyY: mimc7.F.toObject(publicKey[1]).toString(),
    farcasterR8x: mimc7.F.toObject(signature.R8[0]).toString(),
    farcasterR8y: mimc7.F.toObject(signature.R8[1]).toString(),
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
