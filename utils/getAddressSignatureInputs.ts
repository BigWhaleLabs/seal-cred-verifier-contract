import { BigNumber } from 'ethers'
import { buildBabyjub, buildMimc7 } from 'circomlibjs'
import eddsaSign from './eddsaSign'

export default async function (address: string) {
  const babyJub = await buildBabyjub()
  const F = babyJub.F
  const mimc7 = await buildMimc7()
  const hash = mimc7.multiHash([BigNumber.from(address)])
  const { publicKey, signature } = await eddsaSign(hash)
  return {
    address,
    addressPubKeyX: F.toObject(publicKey[0]).toString(),
    addressPubKeyY: F.toObject(publicKey[1]).toString(),
    addressR8x: F.toObject(signature.R8[0]).toString(),
    addressR8y: F.toObject(signature.R8[1]).toString(),
    addressS: signature.S.toString(),
  }
}
