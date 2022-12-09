import { BigNumber, utils } from 'ethers'
import {
  getCommitmentFromSignature,
  getMessageForAddress,
  getSealHubValidatorInputs,
} from '@big-whale-labs/seal-hub-kit'
import Mimc7 from '../Mimc7'
import eddsaSign from '../eddsa/eddsaSign'
import getMerkleTreeInputs from './getMerkleTreeInputs'
import wallet from '../wallet'

async function getFarcasterAttestationInputs(ownersMerkleRoot: string) {
  const farcasterBytes = utils.toUtf8Bytes('farcaster')
  const message = [
    0, // "owns" type of attestation
    ownersMerkleRoot,
    ...farcasterBytes,
  ].map((v) => BigNumber.from(v))
  const mimc7 = await new Mimc7().prepare()
  const hash = mimc7.hashWithoutBabyJub(message)
  const { publicKey, signature } = await eddsaSign(hash)
  return {
    farcasterMessage: message.map((n) => n.toHexString()),
    farcasterPubKeyX: mimc7.F.toObject(publicKey[0]).toString(),
    farcasterPubKeyY: mimc7.F.toObject(publicKey[1]).toString(),
    farcasterR8x: mimc7.F.toObject(signature.R8[0]).toString(),
    farcasterR8y: mimc7.F.toObject(signature.R8[1]).toString(),
    farcasterS: signature.S.toString(),
  }
}

export default async function (
  ownerAddress = wallet.address,
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
  ]
) {
  // Get SealHub validator inputs
  const message = getMessageForAddress(wallet.address)
  const signature = await wallet.signMessage(message)
  const commitment = await getCommitmentFromSignature(signature, message)
  const allCommitments = [
    ...Array(99)
      .fill(undefined)
      .map(() => BigNumber.from(utils.randomBytes(32)).toBigInt()),
    commitment,
  ]
  const sealHubValidatorInputs = await getSealHubValidatorInputs(
    signature,
    message,
    undefined,
    allCommitments
  )
  // Get Farcaster verification inputs
  const merkleTreeInputs = await getMerkleTreeInputs(
    [ownerAddress, ...otherAddresses],
    ownerAddress
  )
  return {
    sealHubPathIndices: sealHubValidatorInputs.pathIndices,
    sealHubSiblings: sealHubValidatorInputs.siblings,
    sealHubU: sealHubValidatorInputs.U,
    sealHubS: sealHubValidatorInputs.s,
    sealHubAddress: sealHubValidatorInputs.address,
    ...(await getFarcasterAttestationInputs(merkleTreeInputs.merkleRoot)),
    ownersPathIndices: merkleTreeInputs.pathIndices,
    ownersSiblings: merkleTreeInputs.siblings,
  }
}
