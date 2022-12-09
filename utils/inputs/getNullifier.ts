import MimcSponge from '../MimcSponge'

export default async function (inputs: {
  sealHubU: (string | bigint)[][]
  sealHubS: (string | bigint)[]
  sealHubAddress: string | bigint
}) {
  const k = 4
  const prepHash: (bigint | string)[] = []

  for (let i = 0; i < k; i++) {
    prepHash[i] = inputs.sealHubS[i]
    prepHash[k + i] = inputs.sealHubU[0][i]
    prepHash[2 * k + i] = inputs.sealHubU[1][i]
  }

  prepHash[3 * k] = inputs.sealHubAddress
  prepHash[3 * k + 1] = 69n
  prepHash[3 * k + 2] = 420n

  const mimc7 = await new MimcSponge().prepare()
  const preNullifier = prepHash.flat().map((v) => BigInt(v))
  const nullifier = mimc7.hash(preNullifier)

  return nullifier
}
