import { resolve } from 'path'
import { cwd } from 'process'
import * as snarkjs from 'snarkjs'

export default async function (proofName: string) {
  const callDataString = await snarkjs.groth16.exportSolidityCallData(
    require(resolve(cwd(), `build/proof-${proofName}.json`)),
    require(resolve(cwd(), `build/public-${proofName}.json`))
  )
  const splitData = callDataString.split('],[')
  return {
    a: JSON.parse(`${splitData[0]}]`),
    b: JSON.parse(`[${splitData[1]}],[${splitData[2]}]`),
    c: JSON.parse(`[${splitData[3]}]`),
    input: JSON.parse(`[${splitData[4]}`),
  }
}
