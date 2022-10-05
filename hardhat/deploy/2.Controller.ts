import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

const func: DeployFunction = async function({
  getNamedAccounts,
  deployments,
}: HardhatRuntimeEnvironment) {
  const { deploy } = deployments
  const { deployer, verificationAddress } = await getNamedAccounts()

  const MuseTime = await deployments.get('MuseTime');

  await deploy('MuseTimeController', {
    from: deployer,
    log: true,
    args: [
      MuseTime.address,
      'https://musetime.xyz/~/',
      verificationAddress
    ],
  })
}

export default func

export const tags = ['controller']
