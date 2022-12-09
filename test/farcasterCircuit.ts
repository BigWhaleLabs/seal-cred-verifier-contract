import { assert } from 'chai'
import { utils } from 'ethers'
import { wasm as wasmTester } from 'circom_tester'
import MimcSponge from '../utils/MimcSponge'
import expectAssertFailure from '../utils/expectAssertFailure'
import getFarcasterInputs from '../utils/inputs/getFarcasterInputs'
import wallet from '../utils/wallet'

describe('FarcasterChecker circuit', function () {
  before(async function () {
    this.circuit = await wasmTester('circuits/FarcasterChecker.circom')
    this.baseInputs = await getFarcasterInputs()
    this.mimcSponge = await new MimcSponge().prepare()
  })

  it('should generate the witness successfully and return the correct nullifier', async function () {
    const witness = await this.circuit.calculateWitness(this.baseInputs)
    await this.circuit.assertOut(witness, {})
    // Check the nullifier
    const nullifier = this.mimcSponge.hash([
      ...this.baseInputs.sealHubS,
      ...this.baseInputs.sealHubU[0],
      ...this.baseInputs.sealHubU[1],
      wallet.address,
      '7264817748646751948082916036165286355035506',
    ])
    assert.equal(nullifier, utils.hexlify(witness[12]))
  })
  it('should fail because the siblings are invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      ownersSiblings: this.baseInputs.ownersSiblings.reverse(),
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the pathIndices is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      pathIndices: new Array(this.baseInputs.ownersPathIndices.length).fill(0),
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
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
  it('should fail because the merkle root in farcasterMessage is invalid', async function () {
    const message = this.baseInputs.farcasterMessage
    message[1] =
      '0x0f365c9af0ab76cbc880ba04f287fd4dac5022eec6f5dcc3ebbe3abd5b2f6438'
    const inputs = {
      ...this.baseInputs,
      farcasterMessage: message,
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
  it('should fail because the farcasterR8x is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      farcasterR8x:
        '7212099666815118526535189261030936450885444553115640062674935038466053117366',
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
  it('should fail because the farcasterS is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      farcasterS:
        '3950502661897335750133025420259312129467652226207505500353373422799432347',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
})
