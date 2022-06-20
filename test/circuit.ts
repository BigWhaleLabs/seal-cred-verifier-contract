import { assert } from 'chai'
import { wasm as wasmTester } from 'circom_tester'

const expectedError = (err) => err.message.includes('Assert Failed')

const input = {
  message: [
    48, 120, 98, 102, 55, 52, 52, 56, 51, 68, 66, 57, 49, 52, 49, 57, 50, 98,
    98, 48, 97, 57, 53, 55, 55, 102, 51, 100, 56, 70, 98, 50, 57, 97, 54, 100,
    52, 99, 48, 56, 101, 69, 45, 111, 119, 110, 115, 45, 48, 120, 55, 50, 50,
    66, 48, 54, 55, 54, 70, 52, 53, 55, 97, 70, 101, 49, 51, 101, 52, 55, 57,
    101, 66, 50, 97, 56, 65, 52, 68, 101, 56, 56, 66, 65, 49, 53, 66, 50, 99,
    54, 45, 56, 110, 104, 76, 77, 77,
  ],
  tokenAddress: [
    48, 120, 55, 50, 50, 66, 48, 54, 55, 54, 70, 52, 53, 55, 97, 70, 101, 49,
    51, 101, 52, 55, 57, 101, 66, 50, 97, 56, 65, 52, 68, 101, 56, 56, 66, 65,
    49, 53, 66, 50, 99, 54,
  ],
  pubKeyX:
    '13578469780849928704623562188688413596472689853032556827882124682666588837591',
  pubKeyY:
    '19666119278979591965777251527504328920019005148768920573158906368334798877314',
  R8x: '5531156400626749350384660531173667212099666815118526535189261030936450885444',
  R8y: '8829535308446341320380897334391409050996425369575435553131772475861663948282',
  S: '6765222620750550035337342279943234739505026618973357501330254202593121294',
  M: '53372506772912948865981934166990734138022776710900778254083774573497151961',
}

describe('ERC721OwnershipChecker circuit', function () {
  let circuit

  before(async function () {
    circuit = await wasmTester('circuits/ERC721OwnershipChecker.circom')
  })

  it('should generate the witness successfully', async () => {
    const witness = await circuit.calculateWitness(input)
    await circuit.assertOut(witness, {})
  })
  it('should fail because the message is invalid', async function () {
    const invalidInput = {
      message: [
        45, 111, 119, 110, 115, 45, 48, 120, 55, 50, 50, 66, 48, 54, 55, 54, 70,
        52, 53, 55, 97, 70, 101, 49, 51, 101, 52, 55, 57, 101, 66, 50, 97, 56,
        65, 52, 68, 101, 56, 56, 66, 65, 49, 53, 66, 50, 99, 54, 45, 56, 110,
        104, 76, 77, 77, 48, 120, 98, 102, 55, 52, 52, 56, 51, 68, 66, 57, 49,
        52, 49, 57, 50, 98, 98, 48, 97, 57, 53, 55, 55, 102, 51, 100, 56, 70,
        98, 50, 57, 97, 54, 100, 52, 99, 48, 56, 101, 69,
      ],
      tokenAddress: input.tokenAddress,
      pubKeyX: input.pubKeyX,
      pubKeyY: input.pubKeyY,
      R8x: input.R8x,
      R8y: input.R8y,
      S: input.S,
      M: input.M,
    }
    try {
      await circuit.calculateWitness(invalidInput)
    } catch (err) {
      assert(expectedError(err))
    }
  })
  it('should fail because the tokenAddress is invalid', async function () {
    const invalidInput = {
      message: input.message,
      tokenAddress: [
        52, 55, 57, 101, 66, 50, 97, 56, 65, 52, 68, 101, 56, 56, 66, 65, 49,
        53, 66, 50, 99, 54, 48, 120, 55, 50, 50, 66, 48, 54, 55, 54, 70, 52, 53,
        55, 97, 70, 101, 49, 51, 101,
      ],
      pubKeyX: input.pubKeyX,
      pubKeyY: input.pubKeyY,
      R8x: input.R8x,
      R8y: input.R8y,
      S: input.S,
      M: input.M,
    }
    try {
      await circuit.calculateWitness(invalidInput)
    } catch (err) {
      assert(expectedError(err))
    }
  })
  it('should fail because the pubKeyX is invalid', async function () {
    const invalidInput = {
      message: input.message,
      tokenAddress: input.tokenAddress,
      pubKeyX:
        '64726898530325568278821246826665888375911357846978084992870462356218868841359',
      pubKeyY: input.pubKeyY,
      R8x: input.R8x,
      R8y: input.R8y,
      S: input.S,
      M: input.M,
    }
    try {
      await circuit.calculateWitness(invalidInput)
    } catch (err) {
      assert(expectedError(err))
    }
  })
  it('should fail because the pubKeyY is invalid', async function () {
    const invalidInput = {
      message: input.message,
      tokenAddress: input.tokenAddress,
      pubKeyX: input.pubKeyX,
      pubKeyY:
        '01900514876892057315890636833479887731419666119278979591965777251527504328920',
      R8x: input.R8x,
      R8y: input.R8y,
      S: input.S,
      M: input.M,
    }
    try {
      await circuit.calculateWitness(invalidInput)
    } catch (err) {
      assert(expectedError(err))
    }
  })
  it('should fail because the R8x is invalid', async function () {
    const invalidInput = {
      message: input.message,
      tokenAddress: input.tokenAddress,
      pubKeyX: input.pubKeyX,
      pubKeyY: input.pubKeyY,
      R8x: '7212099666815118526535189261030936450885444553115640062674935038466053117366',
      R8y: input.R8y,
      S: input.S,
      M: input.M,
    }
    try {
      await circuit.calculateWitness(invalidInput)
    } catch (err) {
      assert(expectedError(err))
    }
  })
  it('should fail because the R8y is invalid', async function () {
    const invalidInput = {
      message: input.message,
      tokenAddress: input.tokenAddress,
      pubKeyX: input.pubKeyX,
      pubKeyY: input.pubKeyY,
      R8x: input.R8x,
      R8y: '9964253695754355531317724758616639482828829535308446341320380897334391409050',
      S: input.S,
      M: input.M,
    }
    try {
      await circuit.calculateWitness(invalidInput)
    } catch (err) {
      assert(expectedError(err))
    }
  })
  it('should fail because the S is invalid', async function () {
    const invalidInput = {
      message: input.message,
      tokenAddress: input.tokenAddress,
      pubKeyX: input.pubKeyX,
      pubKeyY: input.pubKeyY,
      R8x: input.R8x,
      R8y: input.R8y,
      S: '3950502661897335750133025420259312129467652226207505500353373422799432347',
      M: input.M,
    }
    try {
      await circuit.calculateWitness(invalidInput)
    } catch (err) {
      assert(expectedError(err))
    }
  })
  it('should fail because the M is invalid', async function () {
    const invalidInput = {
      message: input.message,
      tokenAddress: input.tokenAddress,
      pubKeyX: input.pubKeyX,
      pubKeyY: input.pubKeyY,
      R8x: input.R8x,
      R8y: input.R8y,
      S: input.S,
      M: '73413802277671090077825408377457349715196153372506772912948865981934166990',
    }
    try {
      await circuit.calculateWitness(invalidInput)
    } catch (err) {
      assert(expectedError(err))
    }
  })
})
