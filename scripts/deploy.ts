import { ethers, run } from 'hardhat'

async function main() {
  const [deployer] = await ethers.getSigners()
  // Deploy the contract
  console.log('Deploying contracts with the account:', deployer.address)
  console.log('Account balance:', (await deployer.getBalance()).toString())
  const provider = ethers.provider
  const { chainId } = await provider.getNetwork()
  const chains = {
    1: 'mainnet',
    3: 'ropsten',
    4: 'rinkeby',
    5: 'goerli',
  } as { [chainId: number]: string }
  const chainName = chains[chainId]
  const Verifier = await ethers.getContractFactory('Verifier')
  const verifier = await Verifier.deploy()
  console.log('Deploy tx gas price:', verifier.deployTransaction.gasPrice)
  console.log('Deploy tx gas limit:', verifier.deployTransaction.gasLimit)
  await verifier.deployed()
  const address = verifier.address
  console.log('Contract deployed to:', address)
  console.log('Wait for 1 minute to make sure blockchain is updated')
  await new Promise((resolve) => setTimeout(resolve, 60 * 1000))
  // Try to verify the contract on Etherscan
  try {
    await run('verify:verify', {
      address,
    })
  } catch (err) {
    console.log('Error verifiying contract on Etherscan:', err)
  }
  // Print out the information
  console.log('Verifier deployed and verified on Etherscan!')
  console.log('Contract address:', address)
  console.log(
    'Etherscan URL:',
    `https://${
      chainName !== 'mainnet' ? `${chainName}.` : ''
    }etherscan.io/address/${address}`
  )
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
