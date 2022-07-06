import { assert } from 'chai'
import { wasm as wasmTester } from 'circom_tester'
import { utils } from 'ethers'
import { buildMimcSponge } from 'circomlibjs'
import getEmailInputs from '../utils/getEmailInputs'
import padZerosOnLeftHexString from '../utils/padZerosOnLeftHexString'
import expectAssertFailure from '../utils/expectAssertFailure'

describe('EmailOwnershipChecker circuit', function () {
  before(async function () {
    this.circuit = await wasmTester('circuits/EmailOwnershipChecker.circom')
    this.baseInputs = await getEmailInputs()
  })

  it('should generate the witness successfully', async function () {
    const witness = await this.circuit.calculateWitness(this.baseInputs)
    await this.circuit.assertOut(witness, {})
    // Check the nullifier
    const mimc = await buildMimcSponge()
    const hash = mimc.multiHash([
      this.baseInputs.r2,
      this.baseInputs.s2,
      this.baseInputs.nonce,
    ])
    assert.equal(
      padZerosOnLeftHexString(`0x${mimc.F.toString(hash, 16)}`, 66),
      utils.hexlify(witness[91])
    )
  })
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
