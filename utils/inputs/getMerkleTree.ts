import { BigNumber } from 'ethers'
import { IncrementalMerkleTree } from '@zk-kit/incremental-merkle-tree'
import { buildBabyjub, buildMimc7 } from 'circomlibjs'

export default async function (items: BigNumber[]) {
  const babyJub = await buildBabyjub()
  const F = babyJub.F
  const mimc7 = await buildMimc7()
  const tree = new IncrementalMerkleTree(
    (args) => F.toObject(mimc7.multiHash.bind(mimc7)(args)),
    20,
    BigInt(0)
  )
  for (const item of items) {
    tree.insert(item.toBigInt())
  }
  return tree
}
