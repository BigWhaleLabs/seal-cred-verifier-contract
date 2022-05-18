import { expect } from 'chai'
import { Contract } from 'ethers'
import { ethers } from 'hardhat'

const VALID_PROOF = {
  a: [
    '0x0822278288cd06bc8f13cec22800b9c659d4ec65be08083af691ad37c6b202d7',
    '0x12ad4d551b648c12c62d19d74eaf4117dbc48fa09c34c48548c32b8896c2a47a',
  ],
  b: [
    [
      '0x15d249dccba882718517e79ea1d028b28ebe31c558c6539990ad23fb7a9bd37d',
      '0x1d2816213b2f6449cde19d0a800439a5e745e0df1c003f42a4f37fb1fe6aaf0b',
    ],
    [
      '0x03293ef92005d511455f084019c8d9adf33bd9103bf3259f1453d89c9c995a4a',
      '0x16dfe4be29eb462929a3ee652e01c076c4f891510390648c465540abae6ef673',
    ],
  ],
  c: [
    '0x030136c4a083bef72c090bfc95f860abd50d6a0fb369690d8c18e344007b0784',
    '0x0c98cad99f5ca1a87907e7852add432668a4de09afe0f726650e4f42bb63e14d',
  ],
  input: [
    '0x0000000000000000000000000000000000000000000000000000000000000001',
    '0x0d41fba73f0dcde45a3683b4c16a32c1f0793268b3cfb01c8a1115aefc76da04',
  ],
}
const INVALID_PROOF = {
  a: VALID_PROOF.a,
  b: VALID_PROOF.b,
  c: VALID_PROOF.c,
  input: [
    '0x0000000000000000000000000000000000000000000000000000000000000001',
    '0x0c98cad99f5ca1a87907e7852add432668a4de09afe0f726650e4f42bb63e14d',
  ],
}

describe('Verifier contract', function () {
  let contract: Contract

  before(async () => {
    const factory = await ethers.getContractFactory('Verifier')
    contract = await factory.deploy()

    await contract.deployed()
  })

  it('should successfully verify proof', async () => {
    const { a, b, c, input } = VALID_PROOF

    expect(await contract.verifyProof(a, b, c, input)).to.be.equal(true)
  })

  it('should successfully verify proof', async () => {
    const { a, b, c, input } = INVALID_PROOF

    expect(await contract.verifyProof(a, b, c, input)).to.be.equal(false)
  })
})
