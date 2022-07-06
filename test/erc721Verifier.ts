import { expect } from 'chai'
import { ethers } from 'hardhat'

const validProof = {
  a: [
    '0x033d7a77e4f81ace753b7e4ea774c1db3977aa0bd2f6850daeedfa5d13567cad',
    '0x27e79e5df6c42fcab66c4970b5bfd682c171dc3f179b2e9233f91dcd462c60d2',
  ],
  b: [
    [
      '0x040afac2353066e6690950379904cadfe34db90f3d3591da7a848f5242bf0acf',
      '0x0a87643fb52c005cb1416c906a7f1f22098949d45bf28e2d0a77330103131b8e',
    ],
    [
      '0x1d7b548eb3e2fc5bd380e16284744d64d2c22eb029e7f992f5d2fc361e1c56b9',
      '0x14dd81d5c26baf94cd5754a9b168f6d72d6c4c4556ee91da2b395cd3905f23bf',
    ],
  ],
  c: [
    '0x017ed4dd83e8cf12a5c6362524eeeffeb884c1d54d8244005a7d15a3ae343258',
    '0x274896422586481fa6d339af4cad95c7f956886c852d23dded07dada2253f35e',
  ],
  input: [
    '0x1dfb0ff3078fff3f3f9165305309d9c0d42bc49f31826d12ebed63827cd7cc6e',
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
    '0x0ac878536cc194714e665549cb408816c390908785da1d9bc4b0e57770b1f5b5',
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

describe('ERC721OwnershipCheckerVerifier contract', function () {
  before(async function () {
    const factory = await ethers.getContractFactory(
      'ERC721OwnershipCheckerVerifier'
    )
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
