import { assert } from 'chai'
import { wasm as wasmTester } from 'circom_tester'
import { BigNumber, utils } from 'ethers'
import { buildMimcSponge } from 'circomlibjs'
import getBalanceInputs from '../utils/getBalanceInputs'
import padZerosOnLeftHexString from '../utils/padZerosOnLeftHexString'
import { maxUInt256, zero } from '../utils/constants'
import expectAssertFailure from '../utils/expectAssertFailure'

describe('BalanceChecker circuit', function () {
  before(async function () {
    this.circuit = await wasmTester('circuits/BalanceChecker.circom')
    this.baseInputs = await getBalanceInputs()
  })

  it('should generate the witness successfully and return the correct nullifier', async function () {
    const inputs = await getBalanceInputs()
    const witness = await this.circuit.calculateWitness(inputs)
    await this.circuit.assertOut(witness, {})
    // Check the nullifier
    const mimc = await buildMimcSponge()
    const hash = mimc.multiHash([inputs.r2, inputs.s2, inputs.nonce])
    assert.equal(
      padZerosOnLeftHexString(`0x${mimc.F.toString(hash, 16)}`, 66),
      utils.hexlify(witness[44])
    )
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
      if (balance.gte(threshold)) {
        resultsToInputs.success.push([
          balance.toHexString(),
          threshold.toHexString(),
        ])
      } else {
        resultsToInputs.failure.push([
          balance.toHexString(),
          threshold.toHexString(),
        ])
      }
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
  it('should fail because the message is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      message: [
        ...this.baseInputs.message.slice(0, -1),
        this.baseInputs.message.at(-1) + 1,
      ],
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the pubKeyX is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      pubKeyX:
        '64726898530325568278821246826665888375911357846978084992870462356218868841359',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the pubKeyY is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      pubKeyY:
        '01900514876892057315890636833479887731419666119278979591965777251527504328920',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the R8x is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      R8x: '7212099666815118526535189261030936450885444553115640062674935038466053117366',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the R8y is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      R8y: '9964253695754355531317724758616639482828829535308446341320380897334391409050',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the S is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      S: '3950502661897335750133025420259312129467652226207505500353373422799432347',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the M is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      M: '73413802277671090077825408377457349715196153372506772912948865981934166990',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
})
