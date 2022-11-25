export type BigIntOrString = bigint | string

export interface Input {
  U: BigIntOrString[][]
  r: BigIntOrString[][]
  s: BigIntOrString[][]
  pubKey: BigIntOrString[][]
}
