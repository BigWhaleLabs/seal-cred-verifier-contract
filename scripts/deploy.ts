import { ethers, run } from 'hardhat'

async function main() {
  const [deployer] = await ethers.getSigners()

  console.log('Deploying contracts with the account:', deployer.address)
  console.log('Account balance:', (await deployer.getBalance()).toString())

  const dosuInvitesAddress = '0x32664A3CD741822d127b00BBCBBAD5e3E857B83A'
  const sealCredLedgerAddress = '0xAD8ab3705d9020a5fe9e2D3790E74E8BC56651A1'

  const factory = await ethers.getContractFactory('Verifier')
  const contract = await factory.deploy()

  console.log('Deploy tx gas price:', contract.deployTransaction.gasPrice)
  console.log('Deploy tx gas limit:', contract.deployTransaction.gasLimit)

  await contract.deployed()

  console.log('✅ SealCred Verifier deployed to:', contract.address)

  console.log('Wait for 1 minute')
  await new Promise((resolve) => setTimeout(resolve, 60000))

  await run('verify:verify', {
    address: "0x179229a0d27E97e98F1d7474001a5C154c2d3566",
  })

  console.log('✅ SealCred Verifier contract verified on Etherscan')
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
