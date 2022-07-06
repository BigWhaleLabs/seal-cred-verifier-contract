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
    50, 97, 56, 65, 52, 68, 101, 56, 56, 66, 65, 49, 53, 66, 50, 99, 54,
  ],
  pubKeyX:
    '4877328357478890623967823018480272757589824716691017530689013849938564609461',
  pubKeyY:
    '19319156333180214350448676801453385628019589905553133160599925263402925020311',
  R8x: '17966790780591759696017779584690413367687540059908793639374282142918318767649',
  R8y: '14544297482302945143394579046169367188060103096317511319064754936601293391615',
  S: '967609335072328902186680924470186055089271004235328405041128566363664325687',
  M: '2275624253458579094464483888730946672464378916143331426193859208720759311766',
  r2: '0x4c5a57590544b7fca1f042da3a96b79e66adbaec407b3b7b015db3c30f9837c2',
  s2: '0x3b355fbd053553b4f9bcbc6b002d694c2ffc8524fc471c56469cc33a497f87af',
  nonce: '0x9a63675d6800fae6da',
}

describe('ERC721OwnershipChecker circuit', function () {
  before(async function () {
    this.circuit = await wasmTester('circuits/ERC721OwnershipChecker.circom')
  })

  it('should generate the witness successfully', async function () {
    const witness = await this.circuit.calculateWitness(input)
    await this.circuit.assertOut(witness, {})
    // Check the nullifier
    const mimc = await buildMimcSponge()
    const hash = mimc.multiHash([
      '0x4c5a57590544b7fca1f042da3a96b79e66adbaec407b3b7b015db3c30f9837c2',
      '0x3b355fbd053553b4f9bcbc6b002d694c2ffc8524fc471c56469cc33a497f87af',
      '0x9a63675d6800fae6da',
    ])
    assert.equal(
      padZeroesOnLeftHexString(`0x${mimc.F.toString(hash, 16)}`, 66),
      utils.hexlify(witness[43])
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
        66, 50, 99, 55,
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
