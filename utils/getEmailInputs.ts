import { buildBabyjub, buildMimc7 } from 'circomlibjs'
import { utils } from 'ethers'
import eddsaSign from './eddsaSign'
import getSignatureInputs from './getSignatureInputs'
import padZeroesOnRightUint8 from './padZeroesOnRightUint8'

export default async function (domain = 'bigwhalelabs.com') {
  const maxDomainLength = 90
  // Message
  const domainBytes = padZeroesOnRightUint8(
    utils.toUtf8Bytes(domain),
    maxDomainLength
  )
  const mimc7 = await buildMimc7()
  const M = mimc7.multiHash(domainBytes)
  // EdDSA
  const { publicKey, signature } = await eddsaSign(M)
  // Generating inputs
  const babyJub = await buildBabyjub()
  const F = babyJub.F
  return {
    message: Array.from(domainBytes),
    pubKeyX: F.toObject(publicKey[0]).toString(),
    pubKeyY: F.toObject(publicKey[1]).toString(),
    R8x: F.toObject(signature.R8[0]).toString(),
    R8y: F.toObject(signature.R8[1]).toString(),
    S: signature.S.toString(),
    M: F.toObject(M).toString(),
    ...(await getSignatureInputs()),
  }
}
