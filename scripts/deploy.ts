import { ethers, run } from 'hardhat'

async function main() {
  const [deployer] = await ethers.getSigners()

  console.log('Deploying contracts with the account:', deployer.address)
  console.log('Account balance:', (await deployer.getBalance()).toString())

  const dosuInvitesAddress = '0x399f4a0a9d6E8f6f4BD019340e4d1bE0C9a742F0'
  const sealCredLedgerAddress = '0x6d638815402a6B2085ad9d6327C27d7796628851'

  const factory = await ethers.getContractFactory('SealCredDerivative')
  const contract = await factory.deploy(dosuInvitesAddress, sealCredLedgerAddress)

  await contract.deployed()

  console.log('✅ SealCred Derivative deployed to:', contract.address)

  console.log('Wait for 1 minute')
  await new Promise((resolve) => setTimeout(resolve, 60000))

  await run('verify:verify', {
    address: contract.address,
    constructorArguments: [
      dosuInvitesAddress,
      sealCredLedgerAddress
    ]
  })

  console.log('✅ SealCred Derivative verified')
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
