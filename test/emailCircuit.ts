import { assert } from 'chai'
import { wasm as wasmTester } from 'circom_tester'

const expectedError = (err) => err.message.includes('Assert Failed')

const input = {
  message: [
    98, 105, 103, 119, 104, 97, 108, 101, 108, 97, 98, 115, 46, 99, 111, 109, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 68, 81,
    78, 102, 66, 76, 71, 66, 57, 78, 102, 55, 109, 78,
  ],
  domain: [
    98, 105, 103, 119, 104, 97, 108, 101, 108, 97, 98, 115, 46, 99, 111, 109, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ],
  pubKeyX:
    '13578469780849928704623562188688413596472689853032556827882124682666588837591',
  pubKeyY:
    '19666119278979591965777251527504328920019005148768920573158906368334798877314',
  R8x: '18037317446510205454180319869937649113598256470922650759974542808891120159433',
  R8y: '12484026953218569110740037765569782666963689212240538835005042866284150757738',
  S: '2258075998464064067251274816705483620870666175514002579601824973687345851209',
  M: '4740523956788044718649205047848392912920478793904197744615877954894163783640',
}

describe('ERC721OwnershipChecker circuit', function () {
  before(async function () {
    this.circuit = await wasmTester('circuits/EmailOwnershipChecker.circom')
  })

  it('should generate the witness successfully', async function () {
    const witness = await this.circuit.calculateWitness(input)
    await this.circuit.assertOut(witness, {})
  })
  it('should fail because the message is invalid', async function () {
    const invalidInput = {
      ...input,
      message: [
        98, 105, 103, 119, 104, 97, 108, 101, 108, 97, 98, 115, 46, 99, 111,
        109, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 68, 81, 78, 102, 66, 76, 71, 66, 57, 78, 102, 55, 109, 79,
      ],
    }
    try {
      await this.circuit.calculateWitness(invalidInput)
    } catch (err) {
      assert(expectedError(err))
    }
  })
  it('should fail because the domain is invalid', async function () {
    const invalidInput = {
      ...input,
      domain: [
        98, 105, 103, 119, 104, 97, 108, 101, 108, 97, 98, 115, 46, 99, 109,
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
