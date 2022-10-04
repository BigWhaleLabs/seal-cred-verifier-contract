import { utils } from 'ethers'
import Mimc7 from '../Mimc7'
import eddsaSign from '../eddsa/eddsaSign'
import getNonceInputs from './getNonceInputs'
import padZeroesOnRightUint8 from '../padZeroesOnRightUint8'

export default async function (domain = 'bigwhalelabs.com') {
  const maxDomainLength = 90
  // Message
  const domainBytes = padZeroesOnRightUint8(
    utils.toUtf8Bytes(domain),
    maxDomainLength
  )
  const mimc7 = await new Mimc7().prepare()
  const hash = mimc7.hashWithoutBabyJub(domainBytes)
  // EdDSA
  const { publicKey, signature } = await eddsaSign(hash)
  // Generating inputs
  return {
    message: Array.from(domainBytes),
    pubKeyX: mimc7.F.toObject(publicKey[0]).toString(),
    pubKeyY: mimc7.F.toObject(publicKey[1]).toString(),
    R8x: mimc7.F.toObject(signature.R8[0]).toString(),
    R8y: mimc7.F.toObject(signature.R8[1]).toString(),
    S: signature.S.toString(),
    nonce: getNonceInputs(),
  }
}
