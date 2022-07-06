import { buildBabyjub, buildEddsa, buildMimc7 } from 'circomlibjs'
import { BigNumber, utils, Wallet } from 'ethers'
import { writeFileSync } from 'fs'
import * as ed from '@noble/ed25519'
import { resolve } from 'path'
import { cwd } from 'process'
import { Entropy, charset16 } from 'entropy-string'

const entropy = new Entropy({ total: 1e6, risk: 1e9, charset: charset16 })

function padZeroesOnRightUint8(array: Uint8Array, length: number) {
  const padding = new Uint8Array(length - array.length)
  return utils.concat([array, padding])
}

const privateKeyBytes = utils.arrayify(
  '0xfe9e8f75954709b4ca5ecd83e31da941ca97a9b518b846c9e1eceafedea363cf'
) // ed.utils.randomPrivateKey()
const randomWallet = Wallet.createRandom()

async function eddsaSign(message: Uint8Array) {
  const eddsa = await buildEddsa()
  const privateKey = utils.arrayify(privateKeyBytes)
  const publicKey = eddsa.prv2pub(privateKey)
  const signature = eddsa.signMiMC(privateKey, message)
  return {
    publicKey,
    signature,
  }
}

async function getSignatureInputs(message = 'For SealCred') {
  const signature = await randomWallet.signMessage(message)
  const { r: r2, s: s2 } = utils.splitSignature(signature)
  return { r2, s2, nonce: `0x${entropy.string()}` }
}

async function generateERC721Input() {
  // Message
  const ownerAddress = '0xbf74483DB914192bb0a9577f3d8Fb29a6d4c08eE'
  const tokenAddress = '0x722B0676F457aFe13e479eB2a8A4De88BA15B2c6'
  const message = `${ownerAddress}owns${tokenAddress}`
  const messageUInt8 = utils.toUtf8Bytes(message)
  const mimc7 = await buildMimc7()
  const M = mimc7.multiHash(messageUInt8)
  // EdDSA
  const { publicKey, signature } = await eddsaSign(M)
  // Generating inputs
  const babyJub = await buildBabyjub()
  const F = babyJub.F
  const inputs = {
    message: Array.from(messageUInt8),
    tokenAddress: Array.from(utils.toUtf8Bytes(tokenAddress)),
    pubKeyX: F.toObject(publicKey[0]).toString(),
    pubKeyY: F.toObject(publicKey[1]).toString(),
    R8x: F.toObject(signature.R8[0]).toString(),
    R8y: F.toObject(signature.R8[1]).toString(),
    S: signature.S.toString(),
    M: F.toObject(M).toString(),
    ...(await getSignatureInputs()),
  }
  // Writing inputs
  writeFileSync(
    resolve(cwd(), 'inputs/input-erc721.json'),
    JSON.stringify(inputs),
    'utf-8'
  )
  console.log('Generated input-erc721.json!')
}

async function generateEmailInput() {
  const maxDomainLength = 90
  // Message
  const domain = 'bigwhalelabs.com'
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
  const inputs = {
    message: Array.from(domainBytes),
    domain: Array.from(domainBytes),
    pubKeyX: F.toObject(publicKey[0]).toString(),
    pubKeyY: F.toObject(publicKey[1]).toString(),
    R8x: F.toObject(signature.R8[0]).toString(),
    R8y: F.toObject(signature.R8[1]).toString(),
    S: signature.S.toString(),
    M: F.toObject(M).toString(),
    ...(await getSignatureInputs()),
  }
  // Writing inputs
  writeFileSync(
    resolve(cwd(), 'inputs/input-email.json'),
    JSON.stringify(inputs),
    'utf-8'
  )
  console.log('Generated input-email.json!')
}

async function generateEthereumBalanceInput() {
  // Message
  const ownerAddress = '0xbf74483DB914192bb0a9577f3d8Fb29a6d4c08eE'
  const balance = '0x6b87c4e204970e6'
  const message = `${ownerAddress}g`
  const messageUInt8 = utils.toUtf8Bytes(message)
  const mimc7 = await buildMimc7()
  const M = mimc7.multiHash([...messageUInt8, balance])
  // EdDSA
  const { publicKey, signature } = await eddsaSign(M)
  // Generating inputs
  const babyJub = await buildBabyjub()
  const F = babyJub.F
  const inputs = {
    message: Array.from(messageUInt8),
    balance,
    pubKeyX: F.toObject(publicKey[0]).toString(),
    pubKeyY: F.toObject(publicKey[1]).toString(),
    R8x: F.toObject(signature.R8[0]).toString(),
    R8y: F.toObject(signature.R8[1]).toString(),
    S: signature.S.toString(),
    M: F.toObject(M).toString(),
    threshold: '0x0',
    ...(await getSignatureInputs()),
  }
  // Writing inputs
  writeFileSync(
    resolve(cwd(), 'inputs/input-ethereum-balance.json'),
    JSON.stringify(inputs),
    'utf-8'
  )
  console.log('Generated input-ethereum-balance.json!')
}

;(async () => {
  console.log('EdDSA private key', utils.hexlify(privateKeyBytes))
  console.log(
    'EdDSA public key',
    BigNumber.from(await ed.getPublicKey(privateKeyBytes)).toString()
  )
  await generateERC721Input()
  await generateEmailInput()
  await generateEthereumBalanceInput()
})()
