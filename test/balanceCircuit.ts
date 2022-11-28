import { BigNumber, utils } from 'ethers'
import { assert, expect } from 'chai'
import { buildMimcSponge } from 'circomlibjs'
import { maxUInt256, zero } from '../utils/constants'
import { wasm as wasmTester } from 'circom_tester'
import expectAssertFailure from '../utils/expectAssertFailure'
import getBalanceInputs from '../utils/inputs/getBalanceInputs'
import padZerosOnLeftHexString from '../utils/padZerosOnLeftHexString'

describe('BalanceChecker circuit', function () {
  before(async function () {
    this.circuit = await wasmTester('circuits/BalanceChecker.circom')
    this.baseInputs = await getBalanceInputs()
  })

  it('should generate the witness successfully and return the correct nullifier', async function () {
    const witness = await this.circuit.calculateWitness(this.baseInputs)
    await this.circuit.assertOut(witness, {})
    // Check the nullifier
    const mimc = await buildMimcSponge()
    const hash = mimc.multiHash(this.baseInputs.nonce)
    assert.equal(
      padZerosOnLeftHexString(`0x${mimc.F.toString(hash, 16)}`, 66),
      utils.hexlify(witness[6])
    )
  })
  it('should return the correct network byte for mainnet', async function () {
    const inputs = await getBalanceInputs(
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      'm'
    )
    const witness = await this.circuit.calculateWitness(inputs)
    await this.circuit.assertOut(witness, {})
    expect(witness[4]).to.be.deep.equal(BigNumber.from(0x6d))
  })
  it('should return the correct network byte for goerli', async function () {
    const inputs = await getBalanceInputs(
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      'g'
    )
    const witness = await this.circuit.calculateWitness(inputs)
    await this.circuit.assertOut(witness, {})
    expect(witness[4]).to.be.deep.equal(BigNumber.from(0x67))
  })
  it('should fail because the siblings is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      siblings: this.baseInputs.siblings.reverse(),
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the pathIndices is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      pathIndices: new Array(this.baseInputs.siblings.length).fill(7),
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  // Generate and test possible edge cases
  const testValues = [zero, '0x1', '0x6b87c4e204970e6', maxUInt256].map((v) =>
    BigNumber.from(v)
  )
  const resultsToInputs = {
    success: [],
    failure: [],
  } as {
    success: string[][]
    failure: string[][]
  }
  for (const balance of testValues) {
    for (const threshold of testValues) {
      const inputs = balance.gte(threshold)
        ? resultsToInputs.success
        : resultsToInputs.failure
      inputs.push([balance.toHexString(), threshold.toHexString()])
    }
  }
  for (const [balance, threshold] of resultsToInputs.success) {
    it(`should succeed for balance ${balance} and threshold ${threshold}`, async function () {
      const inputs = await getBalanceInputs(balance, threshold)
      const witness = await this.circuit.calculateWitness(inputs)
      await this.circuit.assertOut(witness, {})
    })
  }
  for (const [balance, threshold] of resultsToInputs.failure) {
    it(`should fail for balance ${balance} and threshold ${threshold}`, async function () {
      const inputs = await getBalanceInputs(balance, threshold)
      await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
    })
  }
  it('should fail because the balanceMessage is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      balanceMessage: [
        ...this.baseInputs.balanceMessage.slice(0, -1),
        this.baseInputs.balanceMessage.at(-1) + 1,
      ],
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the merkle root in balanceMessage is invalid', async function () {
    const message = this.baseInputs.balanceMessage
    message[1] =
      '0x25467bc5101e722a993cd81390c550a7239974dc73479fb399603a2e3f75cf69'
    const inputs = {
      ...this.baseInputs,
      balanceMessage: message,
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the tokenId in balanceMessage is invalid', async function () {
    const message = this.baseInputs.balanceMessage
    message[2] = '0x1'
    const inputs = {
      ...this.baseInputs,
      balanceMessage: message,
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the addressPubKeyX is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      addressPubKeyX:
        '64726898530325568278821246826665888375911357846978084992870462356218868841359',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the balancePubKeyX is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      balancePubKeyX:
        '64726898530325568278821246826665888375911357846978084992870462356218868841359',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the addressPubKeyY is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      addressPubKeyY:
        '01900514876892057315890636833479887731419666119278979591965777251527504328920',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the balancePubKeyY is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      balancePubKeyY:
        '01900514876892057315890636833479887731419666119278979591965777251527504328920',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the addressR8x is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      addressR8x:
        '7212099666815118526535189261030936450885444553115640062674935038466053117366',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the balanceR8x is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      balanceR8x:
        '7212099666815118526535189261030936450885444553115640062674935038466053117366',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the addressR8y is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      addressR8y:
        '9964253695754355531317724758616639482828829535308446341320380897334391409050',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the balanceR8y is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      balanceR8y:
        '9964253695754355531317724758616639482828829535308446341320380897334391409050',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the addressS is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      addressS:
        '3950502661897335750133025420259312129467652226207505500353373422799432347',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the balanceS is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      balanceS:
        '3950502661897335750133025420259312129467652226207505500353373422799432347',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the nonce is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      nonce: this.baseInputs.nonce.reverse(),
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the address is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      address: '0x425f473795b15fae7310cfb3b4ba8e0bfeffc421',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
})
