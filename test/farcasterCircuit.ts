import { assert } from 'chai'
import { buildMimcSponge } from 'circomlibjs'
import { utils } from 'ethers'
import { wasm as wasmTester } from 'circom_tester'
import expectAssertFailure from '../utils/expectAssertFailure'
import getFarcasterInputs from '../utils/inputs/getFarcasterInputs'
import padZerosOnLeftHexString from '../utils/padZerosOnLeftHexString'

describe('FarcasterChecker circuit', function () {
  before(async function () {
    this.circuit = await wasmTester('circuits/FarcasterChecker.circom')
    this.baseInputs = await getFarcasterInputs()
  })

  it('should generate the witness successfully and return the correct nullifier', async function () {
    const witness = await this.circuit.calculateWitness(this.baseInputs)
    await this.circuit.assertOut(witness, {})
    // Check the nullifier
    const mimc = await buildMimcSponge()
    const hash = mimc.multiHash(this.baseInputs.nonce)
    assert.equal(
      padZerosOnLeftHexString(`0x${mimc.F.toString(hash, 16)}`, 66),
      utils.hexlify(witness[11])
    )
  })
  it('should fail because the farcasterMessage is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      farcasterMessage: [
        ...this.baseInputs.farcasterMessage.slice(0, -1),
        this.baseInputs.farcasterMessage.at(-1) + 1,
      ],
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the farcasterPubKeyX is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      farcasterPubKeyX:
        '64726898530325568278821246826665888375911357846978084992870462356218868841359',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the farcasterPubKeyY is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      farcasterPubKeyY:
        '64726898530325568278821246826665888375911357846978084992870462356218868841359',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the addressPubKeyX is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      addressPubKeyX:
        '01900514876892057315890636833479887731419666119278979591965777251527504328920',
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
  it('should fail because the addressR8x is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      addressR8x:
        '7212099666815118526535189261030936450885444553115640062674935038466053117366',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the farcasterR8x is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      farcasterR8x:
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
  it('should fail because the farcasterR8y is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      farcasterR8y:
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
  it('should fail because the farcasterS is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      farcasterS:
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
