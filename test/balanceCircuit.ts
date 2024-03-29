import { assert } from 'chai'
import { utils } from 'ethers'
import { wasm as wasmTester } from 'circom_tester'
import MimcSponge from '../utils/MimcSponge'
import expectAssertFailure from '../utils/expectAssertFailure'
import getBalanceInputs from '../utils/inputs/getBalanceInputs'
import wallet from '../utils/wallet'

describe('BalanceChecker circuit', function () {
  before(async function () {
    this.circuit = await wasmTester('circuits/BalanceChecker.circom')
    this.baseInputs = await getBalanceInputs()
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
      '110852321604106932801557041130035372901', // "SealCred Balance" in decimal
    ])
    assert.equal(nullifier, utils.hexlify(witness[7]))
  })
  it('should return the correct network byte for mainnet', async function () {
    const inputs = await getBalanceInputs(
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      'm'
    )
    const witness = await this.circuit.calculateWitness(inputs)
    await this.circuit.assertOut(witness, {})
    assert.equal(witness[4], 0x6d)
  })
  it('should return the correct network byte for goerli', async function () {
    const inputs = await getBalanceInputs(
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      'g'
    )
    const witness = await this.circuit.calculateWitness(inputs)
    await this.circuit.assertOut(witness, {})
    assert.equal(witness[4], 0x67)
  })
  it('should fail because the owners siblings are invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      ownersSiblings: this.baseInputs.ownersSiblings.reverse(),
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the ownersPathIndices is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      pathIndices: new Array(this.baseInputs.ownersPathIndices.length).fill(0),
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the balanceMessage is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      balanceMessage: [
        ...this.baseInputs.balanceMessage.slice(0, -1),
        this.baseInputs.balanceMessage.at(-1) + 1,
      ],
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the merkle root in balanceMessage is invalid', async function () {
    const message = this.baseInputs.balanceMessage
    message[1] =
      '0x25467bc5101e722a993cd81390c550a7239974dc73479fb399603a2e3f75cf69'
    const inputs = {
      ...this.baseInputs,
      balanceMessage: message,
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the tokenId in balanceMessage is invalid', async function () {
    const message = this.baseInputs.balanceMessage
    message[3] = '0x1'
    const inputs = {
      ...this.baseInputs,
      balanceMessage: message,
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the balancePubKeyX is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      balancePubKeyX:
        '64726898530325568278821246826665888375911357846978084992870462356218868841359',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the balancePubKeyY is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      balancePubKeyY:
        '01900514876892057315890636833479887731419666119278979591965777251527504328920',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the balanceR8x is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      balanceR8x:
        '7212099666815118526535189261030936450885444553115640062674935038466053117366',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the balanceR8y is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      balanceR8y:
        '9964253695754355531317724758616639482828829535308446341320380897334391409050',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
  it('should fail because the balanceS is invalid', async function () {
    const inputs = {
      ...this.baseInputs,
      balanceS:
        '3950502661897335750133025420259312129467652226207505500353373422799432347',
    }
    await expectAssertFailure(() => this.circuit.calculateWitness(inputs))
  })
})
