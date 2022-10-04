import { BigNumber } from 'ethers'
import { IncrementalMerkleTree } from '@zk-kit/incremental-merkle-tree'
import { buildMimcSponge } from 'circomlibjs'

export default async function (items: BigNumber[]) {
  const mimcSponge = await buildMimcSponge()
  const tree = new IncrementalMerkleTree(
    mimcSponge.multiHash.bind(mimcSponge),
    20,
    BigInt(0)
  )
  for (const item of items) {
    tree.insert(item.toBigInt())
  }
  return tree
}
