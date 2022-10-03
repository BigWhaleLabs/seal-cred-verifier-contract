import { BigNumber, utils } from 'ethers'
import { buildBabyjub, buildMimc7 } from 'circomlibjs'
import eddsaSign from './eddsaSign'
import getMerkleTree from './getMerkleTree'
import getNonceInputs from './getNonceInputs'

async function inputsForMessage(
  message: string,
  suffix: string,
  ownersMerkleRoot?: string,
  threshold?: string
) {
  const babyJub = await buildBabyjub()
  const F = babyJub.F
  const messageUInt8 = utils.toUtf8Bytes(message)
  const messageBytes = ownersMerkleRoot
    ? [...messageUInt8, ownersMerkleRoot]
    : messageUInt8
  const mimc7 = await buildMimc7()
  const M = mimc7.multiHash(messageBytes)
  const { publicKey, signature } = await eddsaSign(M)
  return {
    [`message${suffix}`]: Array.from(messageUInt8),
    [`pubKeyX${suffix}`]: F.toObject(publicKey[0]).toString(),
    [`pubKeyY${suffix}`]: F.toObject(publicKey[1]).toString(),
    [`R8x${suffix}`]: F.toObject(signature.R8[0]).toString(),
    [`R8y${suffix}`]: F.toObject(signature.R8[1]).toString(),
    [`S${suffix}`]: signature.S.toString(),
    [`M${suffix}`]: F.toObject(M).toString(),
    ownersMerkleRoot,
    threshold,
  }
}

export default async function (
  threshold = '0x1',
  ownerAddress = '0xbf74483DB914192bb0a9577f3d8Fb29a6d4c08eE',
  otherAddresses = [
    '0x8ac28b06fC1eEAA8646c0d8A5e835B96e93D6799',
    '0xdb2BA58f1CB7b10698A9Be268cB846809F0B05e4',
    '0x9B55710351F7f4ae1727c66A140734c483CD1269',
    '0x17Faf610A5538DB09282650596B4B7858195e32E',
    '0x2f996d1EABd2325Df2d7532fEEA3EF336FF15b71',
    '0x477b73ce3A4D9Fe4547c4AFf901F991751aaCbE0',
    '0xC21CB669C1829c07AECBB985b223EC5F1172F88d',
    '0x8132Fc22Bf132078695D95eAC4f72B4BB852802b',
    '0x1Ec63554944D39e95F3B78E31261A32DE2159dDC',
    '0x8920240b8C187501a1c6c4b3a0a2bdC3f508eE3A',
    '0x65685C8f07B54d164E72d99C9A86166B7B5d7508',
    '0x45d7392B65B61989416152B843331e3787AD8076',
    '0x7D4a1135005F81eDbc4095e366470d0e8de54Dd4',
    '0xFa3E408c6eA8487F7c93B73174627498CcAA0b19',
    '0x4E561acfFBa09B13dC7C659cBcdA0F9f18A23817',
    '0x22129799A7975ba0BfD696881B09abFd628B0F0A',
    '0xfDb297f5cd648Be7F30b963543a6e104f3Ec2CA4',
    '0x38ACb9A823226728013d59f306e1A6bFD8b8B6F5',
    '0x8cB2f07637205221E68c88a355A7c8F202A8b830',
    '0x4E1617325eE68426C710F6a911792D74b61850BD',
  ],
  tokenAddress = '0x722B0676F457aFe13e479eB2a8A4De88BA15B2c6',
  network: 'g' | 'm' = 'g'
) {
  const ownerAddresses = [ownerAddress, ...otherAddresses]
    .map((a) => a.toLowerCase())
    .sort()
  const ownersMerkleTree = await getMerkleTree(
    ownerAddresses.map((a) => BigNumber.from(a))
  )
  const ownersMerkleRoot = utils.hexlify(ownersMerkleTree.root)
  const proof = ownersMerkleTree.createProof(
    ownerAddresses.indexOf(ownerAddress.toLowerCase())
  )
  return {
    ...(await inputsForMessage(ownerAddress, 'Address')),
    ...(await inputsForMessage(
      `owns${tokenAddress}${network}`,
      'Token',
      ownersMerkleRoot,
      threshold
    )),
    ...(await getNonceInputs()),
    pathIndices: proof.pathIndices,
    siblings: proof.siblings.map((v) => v[0]).map((v) => utils.hexlify(v)),
  }
}

const nice = {
  messageAddress: [
    48, 120, 98, 102, 55, 52, 52, 56, 51, 68, 66, 57, 49, 52, 49, 57, 50, 98,
    98, 48, 97, 57, 53, 55, 55, 102, 51, 100, 56, 70, 98, 50, 57, 97, 54, 100,
    52, 99, 48, 56, 101, 69,
  ],
  pubKeyXAddress:
    '4877328357478890623967823018480272757589824716691017530689013849938564609461',
  pubKeyYAddress:
    '19319156333180214350448676801453385628019589905553133160599925263402925020311',
  R8xAddress:
    '4677520192386416804963704338597519172003223772076188972505857784152427584708',
  R8yAddress:
    '14406396458018496497613935150682222860140520691729272542410460462597253078969',
  SAddress:
    '1315742568280436810592821099657746630251532633708787205158657373340001661022',
  MAddress:
    '13212816873189175504493684927098539753530031124875322194132256436282521565993',
  ownersMerkleRoot:
    '0x594f71f7083c03e5520692a009c65671f87afefa1181acc10039b3a3ece82005',
  threshold: '0x1',
  messageToken: [
    111, 119, 110, 115, 48, 120, 55, 50, 50, 66, 48, 54, 55, 54, 70, 52, 53, 55,
    97, 70, 101, 49, 51, 101, 52, 55, 57, 101, 66, 50, 97, 56, 65, 52, 68, 101,
    56, 56, 66, 65, 49, 53, 66, 50, 99, 54, 103,
  ],
  pubKeyXToken:
    '4877328357478890623967823018480272757589824716691017530689013849938564609461',
  pubKeyYToken:
    '19319156333180214350448676801453385628019589905553133160599925263402925020311',
  R8xToken:
    '7494907292736691846819801803908587922574062907302404337463250395695371777381',
  R8yToken:
    '19389806372120295377270064490216248629522281110448536865436710882315920263850',
  SToken:
    '2332137058725328112355555979975908785701572073161334763882951719807931525488',
  MToken:
    '8360060685162886207424448337176918081048408465201098913658442531549580666204',
  r2: '0x9286fcb62c49e1e03beffafcdf884bbfb7e8f9097b442d06854f186018954197',
  s2: '0xe6aae8112fc5d63fa805f1ae43d45656524116fab38eb99b503c2cdd43eba87e',
  pathIndices: [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  siblings: [
    '0xc21cb669c1829c07aecbb985b223ec5f1172f88d',
    '0x57294b2ee79372ed05d89fdfe46034e4cc659ba84a543ecdac0b40acc233dc2a',
    '0x205a67553ddea9f909a7738aaee1a46fa3d0610907bd57cdf974f0f1d0e00617',
    '0x0dc60bf6e5bfd42bc04e6ed4aa63bda53716daa0bfa3e03c01d0adc762aa3a21',
    '0x81147dc69a31cdef2cbeeb98910e8ea8c019f3d65b8d65b1c8d0ff4fa87a3605',
    '0x2b0433ef6773d5702471d4c148c29cb27770f7acf297cddac5d6cc39fca42525',
    '0x8d5c6eeee2de66c88e64d9d5d19850090da6acb0d8ea2d0033d7a247e0a17a16',
    '0x0f03ec86bd6fb1052a18ba0040ee34d82494bfa232f70b90b347ab69324bae12',
    '0xc2a0e630cc26cfd8494e10931187e8f998f6d3836bacbba715b872a626361411',
    '0x0f641937059d0be77d8bcb510af71b063469bf8bb77088bc3433635d9243e823',
    '0x805bbf162c0a2c8fb13a0eba8eb769e003dcaf51cd7cb7f4a2d5daac45ee4a1b',
    '0xf974d600abba2af765a69d38bb526c8064f291d72d4ef45f036da60eb4dc812f',
    '0x41b2d252fec77240dd4cfc1c086633eeddb8d83cc18bf189db79fd519d236e08',
    '0xb794718d3574b8ac1791b25bceb99954908f92277fb93da4b7c56c805c987e21',
    '0x4119fa912ce56e7ea8a01e8bbc53213106d19127f15888243eb34ed70a1de712',
    '0xc48e57f0754c47152838091212e88565dc3105c005f813619ee9083ffa7e1d18',
    '0xae0341c1178e45f65a36cd9cdb9330294b8abfa166fc68fd9ae863cab8c04d0e',
    '0xda3273d7deb0e8d1aeacefc924367e2b12c8d11288a0ddf304e435ffb814cc2a',
    '0x1a74377a5020a230cafef95fb046bfad910536318045bbedfdb61e92ead29e0f',
    '0x7a4561ec25a65d30af282cfa1d3ac66f975bc95fe63370ab3a1f0a0874570d0a',
  ],
}
