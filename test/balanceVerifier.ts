import { expect } from 'chai'
import { ethers } from 'hardhat'

const validProof = {
  a: [
    '0x2ab6db17f41384614f9c492b66922764535cc7ca3e537800dd8012fa4e47ba58',
    '0x25b11291ff5cc3528f1ca6b05d5c9b5b2ac8e913658d981705f8701f559004d6',
  ],
  b: [
    [
      '0x27caa940b4d633e0b94f69968fea95afa239486d828e9725fdd31afa7d694593',
      '0x1bbac6a2865a642a5eb68a33765eccdc5d0225112037a3e035a13a999f835f1d',
    ],
    [
      '0x2cfef1a3bbaf59b7f9b3e17a186feaf2be3c5fe30b1cf7e5fc03853ce56e95d6',
      '0x1ab5f0a86855ca89af0f32e3f6c77790d97ba8ce00c9c4dfd705fd24ed00cac0',
    ],
  ],
  c: [
    '0x0e175cbad478fa8a182612cec845479aaadd0dd921d7e7167b81fdfdaf07c680',
    '0x0edf03541514037c4e4da58fbbe774ef8801c33fe550d5c9ec4281679260ad19',
  ],
  input: [
    '0x0000000000000000000000000000000000000000000000000000000000000030',
    '0x0000000000000000000000000000000000000000000000000000000000000078',
    '0x0000000000000000000000000000000000000000000000000000000000000037',
    '0x0000000000000000000000000000000000000000000000000000000000000032',
    '0x0000000000000000000000000000000000000000000000000000000000000032',
    '0x0000000000000000000000000000000000000000000000000000000000000042',
    '0x0000000000000000000000000000000000000000000000000000000000000030',
    '0x0000000000000000000000000000000000000000000000000000000000000036',
    '0x0000000000000000000000000000000000000000000000000000000000000037',
    '0x0000000000000000000000000000000000000000000000000000000000000036',
    '0x0000000000000000000000000000000000000000000000000000000000000046',
    '0x0000000000000000000000000000000000000000000000000000000000000034',
    '0x0000000000000000000000000000000000000000000000000000000000000035',
    '0x0000000000000000000000000000000000000000000000000000000000000037',
    '0x0000000000000000000000000000000000000000000000000000000000000061',
    '0x0000000000000000000000000000000000000000000000000000000000000046',
    '0x0000000000000000000000000000000000000000000000000000000000000065',
    '0x0000000000000000000000000000000000000000000000000000000000000031',
    '0x0000000000000000000000000000000000000000000000000000000000000033',
    '0x0000000000000000000000000000000000000000000000000000000000000065',
    '0x0000000000000000000000000000000000000000000000000000000000000034',
    '0x0000000000000000000000000000000000000000000000000000000000000037',
    '0x0000000000000000000000000000000000000000000000000000000000000039',
    '0x0000000000000000000000000000000000000000000000000000000000000065',
    '0x0000000000000000000000000000000000000000000000000000000000000042',
    '0x0000000000000000000000000000000000000000000000000000000000000032',
    '0x0000000000000000000000000000000000000000000000000000000000000061',
    '0x0000000000000000000000000000000000000000000000000000000000000038',
    '0x0000000000000000000000000000000000000000000000000000000000000041',
    '0x0000000000000000000000000000000000000000000000000000000000000034',
    '0x0000000000000000000000000000000000000000000000000000000000000044',
    '0x0000000000000000000000000000000000000000000000000000000000000065',
    '0x0000000000000000000000000000000000000000000000000000000000000038',
    '0x0000000000000000000000000000000000000000000000000000000000000038',
    '0x0000000000000000000000000000000000000000000000000000000000000042',
    '0x0000000000000000000000000000000000000000000000000000000000000041',
    '0x0000000000000000000000000000000000000000000000000000000000000031',
    '0x0000000000000000000000000000000000000000000000000000000000000035',
    '0x0000000000000000000000000000000000000000000000000000000000000042',
    '0x0000000000000000000000000000000000000000000000000000000000000032',
    '0x0000000000000000000000000000000000000000000000000000000000000063',
    '0x0000000000000000000000000000000000000000000000000000000000000036',
    '0x000000000000000000000000000000000000000000000000000000000000006f',
    '0x06a7b38930d31b38b511c8a1b8135dcba80d730ceb7af68f23129782dce7fc8d',
    '0x0ac878536cc194714e665549cb408816c390908785da1d9bc4b0e57770b1f5b5',
    '0x0000000000000000000000000000000000000000000000000000000000000001',
  ],
}
const invalidProof = {
  a: validProof.a,
  b: validProof.b,
  c: [
    '0x184b074c1fac82c2dda436071d098edb4a2955343721ef642e6b844e40a50cc0',
    '0x1e11078629c2031c0eb203d84f745e423440ed52091d06ece6020cd5674fda5f',
  ],
  input: validProof.input,
}

describe('BalanceCheckerVerifier contract', function () {
  before(async function () {
    const factory = await ethers.getContractFactory('BalanceCheckerVerifier')
    this.contract = await factory.deploy()

    await this.contract.deployed()
  })

  it('should successfully verify correct proof', async function () {
    const { a, b, c, input } = validProof
    const params = [a, b, c, input]
    expect(await this.contract.verifyProof(...params)).to.be.equal(true)
  })

  it('should fail to verify incorrect proof', async function () {
    const { a, b, c, input } = invalidProof

    expect(await this.contract.verifyProof(a, b, c, input)).to.be.equal(false)
  })
})
