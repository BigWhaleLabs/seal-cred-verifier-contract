/* eslint-disable @typescript-eslint/no-explicit-any */
import { buildBabyjub, buildMimcSponge } from 'circomlibjs'

export default class {
  private babyJub: any
  F: any
  private mimcSponge: any

  async prepare() {
    this.babyJub = await buildBabyjub()
    this.F = this.babyJub.F
    this.mimcSponge = await buildMimcSponge()
    return this
  }
  hash(elements: any[] | Uint8Array) {
    return this.F.toObject(
      this.mimcSponge.multiHash.bind(this.mimcSponge)(elements)
    )
  }
  hashWithoutBabyJub(elements: any[] | Uint8Array) {
    return this.mimcSponge.multiHash.bind(this.mimcSponge)(elements)
  }
}
