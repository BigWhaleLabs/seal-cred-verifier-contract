import { assert } from 'chai'
import { wasm as wasmTester } from 'circom_tester'
import { utils } from 'ethers'
import { buildMimcSponge } from 'circomlibjs'

const expectedError = (err) => err.message.includes('Assert Failed')
function padZeroesOnLeftHexString(hexString: string, length: number) {
  const padding = '0'.repeat(length - hexString.length)
  return `0x${padding}${hexString.substring(2)}`
}

const input = {
  message: [
    98, 105, 103, 119, 104, 97, 108, 101, 108, 97, 98, 115, 46, 99, 111, 109, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ],
  pubKeyX:
    '4877328357478890623967823018480272757589824716691017530689013849938564609461',
  pubKeyY:
    '19319156333180214350448676801453385628019589905553133160599925263402925020311',
  R8x: '15298606526480864584355910095334162775602999800896032883635014999175499989355',
  R8y: '10740611045853572746142064534257693773300226817620379210695421925811006659780',
  S: '1951774407546037671953995624213462928595262386347037775045967177714957872170',
  M: '16326699391730603227158046697851865060679964588080600882713030572574027071981',
  r2: '0x4c5a57590544b7fca1f042da3a96b79e66adbaec407b3b7b015db3c30f9837c2',
  s2: '0x3b355fbd053553b4f9bcbc6b002d694c2ffc8524fc471c56469cc33a497f87af',
  nonce: '0x2f61098bba9fc34541',
}

describe('EmailOwnershipChecker circuit', function () {
  before(async function () {
    this.circuit = await wasmTester('circuits/EmailOwnershipChecker.circom')
  })

  it('should generate the witness successfully', async function () {
    const witness = await this.circuit.calculateWitness(input)
    await this.circuit.assertOut(witness, {})
    // Check the nullifier
    const mimc = await buildMimcSponge()
    const hash = mimc.multiHash([input.r2, input.s2, input.nonce])
    assert.equal(
      padZeroesOnLeftHexString(`0x${mimc.F.toString(hash, 16)}`, 66),
      utils.hexlify(witness[91])
    )
  })
  it('should fail because the message is invalid', async function () {
    const invalidInput = {
      ...input,
      message: [
        98, 105, 103, 119, 104, 97, 108, 101, 108, 97, 98, 115, 46, 99, 111,
        109, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0,
      ],
    }
    try {
      await this.circuit.calculateWitness(invalidInput)
    } catch (err) {
      assert(expectedError(err))
    }
  })
  it('should fail because the pubKeyX is invalid', async function () {
    const invalidInput = {
      ...input,
      pubKeyX:
        '64726898530325568278821246826665888375911357846978084992870462356218868841359',
    }
    try {
      await this.circuit.calculateWitness(invalidInput)
    } catch (err) {
      assert(expectedError(err))
    }
  })
  it('should fail because the pubKeyY is invalid', async function () {
    const invalidInput = {
      ...input,
      pubKeyY:
        '01900514876892057315890636833479887731419666119278979591965777251527504328920',
    }
    try {
      await this.circuit.calculateWitness(invalidInput)
    } catch (err) {
      assert(expectedError(err))
    }
  })
  it('should fail because the R8x is invalid', async function () {
    const invalidInput = {
      ...input,
      R8x: '7212099666815118526535189261030936450885444553115640062674935038466053117366',
    }
    try {
      await this.circuit.calculateWitness(invalidInput)
    } catch (err) {
      assert(expectedError(err))
    }
  })
  it('should fail because the R8y is invalid', async function () {
    const invalidInput = {
      ...input,
      R8y: '9964253695754355531317724758616639482828829535308446341320380897334391409050',
    }
    try {
      await this.circuit.calculateWitness(invalidInput)
    } catch (err) {
      assert(expectedError(err))
    }
  })
  it('should fail because the S is invalid', async function () {
    const invalidInput = {
      ...input,
      S: '3950502661897335750133025420259312129467652226207505500353373422799432347',
    }
    try {
      await this.circuit.calculateWitness(invalidInput)
    } catch (err) {
      assert(expectedError(err))
    }
  })
  it('should fail because the M is invalid', async function () {
    const invalidInput = {
      ...input,
      M: '73413802277671090077825408377457349715196153372506772912948865981934166990',
    }
    try {
      await this.circuit.calculateWitness(invalidInput)
    } catch (err) {
      assert(expectedError(err))
    }
  })
})
