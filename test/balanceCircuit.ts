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
    48, 120, 98, 102, 55, 52, 52, 56, 51, 68, 66, 57, 49, 52, 49, 57, 50, 98,
    98, 48, 97, 57, 53, 55, 55, 102, 51, 100, 56, 70, 98, 50, 57, 97, 54, 100,
    52, 99, 48, 56, 101, 69, 111, 119, 110, 115, 48, 120, 55, 50, 50, 66, 48,
    54, 55, 54, 70, 52, 53, 55, 97, 70, 101, 49, 51, 101, 52, 55, 57, 101, 66,
    50, 97, 56, 65, 52, 68, 101, 56, 56, 66, 65, 49, 53, 66, 50, 99, 54, 103,
  ],
  balance: '0x6b87c4e204970e6',
  threshold: '0x1',
  pubKeyX:
    '4877328357478890623967823018480272757589824716691017530689013849938564609461',
  pubKeyY:
    '19319156333180214350448676801453385628019589905553133160599925263402925020311',
  R8x: '10378672807010021053752775560521565036084291032757638995106228305977964368983',
  R8y: '6250041159475330228917392943246508180909119552731282039666974587477562476404',
  S: '1779058063762819078226233234985670173128914491032484240909675976881746011625',
  M: '12456080624582143469089645829478564458865643630206539977874934953790857334143',
  r2: '0x0cb2ce8abc7e1a417d0aff0b7dfa0eeee2d74e9c3c7a54bfec3fb1147f9dbef3',
  s2: '0x3badd63bd095b9ea6c11df64468c50223b04e71115844babe4643ac81fabcf21',
  nonce: '0xcf9b43d9890ed31204',
}

describe('BalanceChecker circuit', function () {
  before(async function () {
    this.circuit = await wasmTester('circuits/BalanceChecker.circom')
  })

  it.only('should generate the witness successfully', async function () {
    const witness = await this.circuit.calculateWitness(input)
    await this.circuit.assertOut(witness, {})
    // Check the nullifier
    const mimc = await buildMimcSponge()
    const hash = mimc.multiHash([input.r2, input.s2, input.nonce])
    assert.equal(
      padZeroesOnLeftHexString(`0x${mimc.F.toString(hash, 16)}`, 66),
      utils.hexlify(witness[44])
    )
  })
  it('should fail because the message is invalid', async function () {
    const invalidInput = {
      ...input,
      message: [
        48, 120, 98, 102, 55, 52, 52, 56, 51, 68, 66, 57, 49, 52, 49, 57, 50,
        98, 98, 48, 97, 57, 53, 55, 55, 102, 51, 100, 56, 70, 98, 50, 57, 97,
        54, 100, 52, 99, 48, 56, 101, 69, 111, 119, 110, 115, 48, 120, 55, 50,
        50, 66, 48, 54, 55, 54, 70, 52, 53, 55, 97, 70, 101, 49, 51, 101, 52,
        55, 57, 101, 66, 50, 97, 56, 65, 52, 68, 101, 56, 56, 66, 65, 49, 53,
        66, 50, 99, 54, 104,
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
