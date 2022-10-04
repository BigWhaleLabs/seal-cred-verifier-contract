/* eslint-disable @typescript-eslint/no-explicit-any */
import { buildBabyjub, buildMimc7 } from 'circomlibjs'

export default class {
  private babyJub: any
  private F: any
  private mimc7: any

  async prepare() {
    this.babyJub = await buildBabyjub()
    this.F = this.babyJub.F
    this.mimc7 = await buildMimc7()
    return this
  }
  hash(elements: any[]) {
    return this.F.toObject(this.mimc7.multiHash.bind(this.mimc7)(elements))
  }
}
