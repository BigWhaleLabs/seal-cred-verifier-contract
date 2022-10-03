import { BigNumber } from 'ethers'
import { IncrementalMerkleTree } from '@zk-kit/incremental-merkle-tree'
import { buildMimc7 } from 'circomlibjs'

export default async function (items: BigNumber[]) {
  const mimc7 = await buildMimc7()
  const tree = new IncrementalMerkleTree(
    mimc7.multiHash.bind(mimc7),
    20,
    BigInt(0)
  )
  for (const item of items) {
    tree.insert(item.toBigInt())
  }
  return tree
}
