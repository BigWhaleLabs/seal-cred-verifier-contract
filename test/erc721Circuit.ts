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
    54, 45, 55, 74, 56, 50, 78, 66, 113, 103, 114, 56, 52, 104, 109, 80,
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
  R8x: '8469436916298365544043193337481098975555446453630628875174746416326023935641',
  R8y: '4474299135580209683611333548207644924142161290447851023506556298859123906410',
  S: '2594716379317334933636582632769435786043094629071510864134279001599598843937',
  M: '18205156670498516442487553783765237156336648508932025207823817239554663865632',
}

describe('ERC721OwnershipChecker circuit', function () {
  before(async function () {
    this.circuit = await wasmTester('circuits/ERC721OwnershipChecker.circom')
  })

  it('should generate the witness successfully', async function () {
    const witness = await this.circuit.calculateWitness(input)
    await this.circuit.assertOut(witness, {})
  })
  it('should fail because the message is invalid', async function () {
    const invalidInput = {
      ...input,
      message: [
        48, 120, 98, 102, 55, 52, 52, 56, 51, 68, 66, 57, 49, 52, 49, 57, 50,
        98, 98, 48, 97, 57, 53, 55, 55, 102, 51, 100, 56, 70, 98, 50, 57, 97,
        54, 100, 52, 99, 48, 56, 101, 69, 45, 111, 119, 110, 115, 45, 48, 120,
        55, 50, 50, 66, 48, 54, 55, 54, 70, 52, 53, 55, 97, 70, 101, 49, 51,
        101, 52, 55, 57, 101, 66, 50, 97, 56, 65, 52, 68, 101, 56, 56, 66, 65,
        49, 53, 66, 50, 99, 54, 45, 100, 77, 55, 50, 110, 81, 50, 98, 71, 54,
        52, 51, 72, 50,
      ],
    }
    try {
      await this.circuit.calculateWitness(invalidInput)
    } catch (err) {
      assert(expectedError(err))
    }
  })
  it('should fail because the tokenAddress is invalid', async function () {
    const invalidInput = {
      ...input,
      tokenAddress: [
        48, 120, 55, 50, 50, 66, 48, 54, 55, 54, 70, 52, 53, 55, 97, 70, 101,
        49, 51, 101, 52, 55, 57, 101, 66, 50, 97, 56, 65, 52, 68, 101, 56, 56,
        66, 65, 49, 53, 66, 50, 99, 54,
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
