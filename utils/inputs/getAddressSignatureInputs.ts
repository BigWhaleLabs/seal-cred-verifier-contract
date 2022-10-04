import { BigNumber } from 'ethers'
import Mimc7 from '../Mimc7'
import eddsaSign from '../eddsa/eddsaSign'

export default async function (address: string) {
  const mimc7 = await new Mimc7().prepare()
  const hash = mimc7.hashWithoutBabyJub([BigNumber.from(address)])
  const { publicKey, signature } = await eddsaSign(hash)
  return {
    address,
    addressPubKeyX: mimc7.F.toObject(publicKey[0]).toString(),
    addressPubKeyY: mimc7.F.toObject(publicKey[1]).toString(),
    addressR8x: mimc7.F.toObject(signature.R8[0]).toString(),
    addressR8y: mimc7.F.toObject(signature.R8[1]).toString(),
    addressS: signature.S.toString(),
  }
}
