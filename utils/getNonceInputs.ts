import { BigNumber, utils } from 'ethers'

export default function () {
  return {
    r2: BigNumber.from(utils.randomBytes(32)).toHexString(),
    s2: BigNumber.from(utils.randomBytes(32)).toHexString(),
  }
}
