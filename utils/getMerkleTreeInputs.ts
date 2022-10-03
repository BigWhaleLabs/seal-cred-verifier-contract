import { BigNumber, utils } from 'ethers'
import getMerkleTree from './getMerkleTree'

export default async function (allElements: string[], element: string) {
  const allElementsSorted = allElements.map((e) => e.toLowerCase()).sort()
  const ownersMerkleTree = await getMerkleTree(
    allElementsSorted.map((v) => BigNumber.from(v))
  )
  const merkleRoot = utils.hexlify(ownersMerkleTree.root)
  const proof = ownersMerkleTree.createProof(
    allElementsSorted.indexOf(element.toLowerCase())
  )
  return {
    merkleRoot,
    pathIndices: proof.pathIndices,
    siblings: proof.siblings.map((v) => v[0]).map((v) => utils.hexlify(v)),
  }
}
