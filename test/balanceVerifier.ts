import { expect } from 'chai'
import { ethers } from 'hardhat'
import { Proof } from '../utils/Proof'
import getSolidityCallProof from '../utils/getSolidityCallProof'

describe('BalanceCheckerVerifier contract', function () {
  before(async function () {
    const factory = await ethers.getContractFactory('BalanceCheckerVerifier')
    this.contract = await factory.deploy()
    await this.contract.deployed()
    this.proof = await getSolidityCallProof('balance')
  })

  it('should successfully verify correct proof', async function () {
    const { a, b, c, input } = this.proof
    const params = [a, b, c, input]
    expect(await this.contract.verifyProof(...params)).to.be.equal(true)
  })

  it('should fail to verify incorrect proof', async function () {
    const { a, b, c, input } = {
      ...this.proof,
      c: [
        '0x184b074c1fac82c2dda436071d098edb4a2955343721ef642e6b844e40a50cc0',
        '0x1e11078629c2031c0eb203d84f745e423440ed52091d06ece6020cd5674fda5f',
      ],
    } as Proof

    expect(await this.contract.verifyProof(a, b, c, input)).to.be.equal(false)
  })
})
