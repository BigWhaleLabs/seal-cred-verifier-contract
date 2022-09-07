import { BigNumber, utils } from 'ethers'
import { assert, expect } from 'chai'
import { buildMimcSponge } from 'circomlibjs'
import { maxUInt256, zero } from '../utils/constants'
import { wasm as wasmTester } from 'circom_tester'
import expectAssertFailure from '../utils/expectAssertFailure'
import getFarcasterInputs from '../utils/getFarcasterInputs'
import padZerosOnLeftHexString from '../utils/padZerosOnLeftHexString'

describe.only('FarcasterChecker circuit', function () {
  before(async function () {
    this.circuit = await wasmTester('circuits/FarcasterChecker.circom')
    this.baseInputs = await getFarcasterInputs()
  })

  it('should generate the witness successfully and return the correct nullifier', async function () {
    const inputs = await getFarcasterInputs()
    const witness = await this.circuit.calculateWitness(inputs)
    await this.circuit.assertOut(witness, {})
    // Check the nullifier
    const mimc = await buildMimcSponge()
    const hash = mimc.multiHash([inputs.r2, inputs.s2])
    console.log(
      padZerosOnLeftHexString(`0x${mimc.F.toString(hash, 16)}`, 66),
      utils.hexlify(witness[9])
    )
    assert.equal(
      padZerosOnLeftHexString(`0x${mimc.F.toString(hash, 16)}`, 66),
      utils.hexlify(witness[9])
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
      const inputs = balance.gte(threshold)
        ? resultsToInputs.success
        : resultsToInputs.failure
      inputs.push([balance.toHexString(), threshold.toHexString()])
    }
  }
  it('should fail because the messageAddress is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      messageAddress: [
        ...this.baseInputs.messageAddress.slice(0, -1),
        this.baseInputs.messageAddress.at(-1) + 1,
      ],
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the messageAddress is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      messageAddress: [
        ...this.baseInputs.messageAddress.slice(0, -1),
        this.baseInputs.messageAddress.at(-1) + 1,
      ],
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the pubKeyXFarcaster is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      pubKeyXFarcaster:
        '64726898530325568278821246826665888375911357846978084992870462356218868841359',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the pubKeyYFarcaster is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      pubKeyYFarcaster:
        '64726898530325568278821246826665888375911357846978084992870462356218868841359',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the pubKeyXAddress is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      pubKeyXAddress:
        '01900514876892057315890636833479887731419666119278979591965777251527504328920',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the pubKeyYAddress is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      pubKeyYAddress:
        '01900514876892057315890636833479887731419666119278979591965777251527504328920',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the R8xAddress is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      R8xAddress:
        '7212099666815118526535189261030936450885444553115640062674935038466053117366',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the R8xFarcaster is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      R8xFarcaster:
        '7212099666815118526535189261030936450885444553115640062674935038466053117366',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the R8yAddress is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      R8yAddress:
        '9964253695754355531317724758616639482828829535308446341320380897334391409050',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the R8yFarcaster is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      R8yFarcaster:
        '9964253695754355531317724758616639482828829535308446341320380897334391409050',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the SAddress is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      SAddress:
        '3950502661897335750133025420259312129467652226207505500353373422799432347',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the SFarcaster is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      SFarcaster:
        '3950502661897335750133025420259312129467652226207505500353373422799432347',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the MAddress is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      MAddress:
        '73413802277671090077825408377457349715196153372506772912948865981934166990',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the MFarcaster is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      MFarcaster:
        '73413802277671090077825408377457349715196153372506772912948865981934166990',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
})
