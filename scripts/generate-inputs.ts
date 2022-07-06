import { BigNumber, utils } from 'ethers'
import { writeFileSync } from 'fs'
import * as ed from '@noble/ed25519'
import { resolve } from 'path'
import { cwd } from 'process'
import eddsaPrivateKeyBytes from '../utils/eddsaPrivateKeyBytes'
import getBalanceInputs from '../utils/getBalanceInputs'
import getEmailInputs from '../utils/getEmailInputs'

async function generateEmailInput() {
  const inputs = await getEmailInputs()
  // Writing inputs
  writeFileSync(
    resolve(cwd(), 'inputs/input-email.json'),
    JSON.stringify(inputs),
    'utf-8'
  )
  console.log('Generated input-email.json!')
}

async function generateBalanceInput() {
  const inputs = await getBalanceInputs()
  // Writing inputs
  writeFileSync(
    resolve(cwd(), 'inputs/input-balance.json'),
    JSON.stringify(inputs),
    'utf-8'
  )
  console.log('Generated input-balance.json!')
}

;(async () => {
  console.log('EdDSA private key', utils.hexlify(eddsaPrivateKeyBytes))
  console.log(
    'EdDSA public key',
    BigNumber.from(await ed.getPublicKey(eddsaPrivateKeyBytes)).toString()
  )
  await generateEmailInput()
  await generateBalanceInput()
})()
