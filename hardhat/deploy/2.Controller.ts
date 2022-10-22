import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

const func: DeployFunction = async function({
  getNamedAccounts,
  deployments,
}: HardhatRuntimeEnvironment) {
  const { deploy } = deployments
  const { deployer, paramsSigner } = await getNamedAccounts()

  const MuseTime = await deployments.get('MuseTime');

  await deploy('MuseTimeController', {
    from: deployer,
    log: true,
    proxy: {
      proxyContract: 'OpenZeppelinTransparentProxy',
      execute: {
        init: {
          methodName: 'initialize',
          args: [
            MuseTime.address,
            'https://musetime.xyz/~/',
            paramsSigner,
          ]
        },
        // onUpgrade: {
        //   methodName: '',
        //   args: []
        // }
      }
    }
  })
}

export default func

export const tags = ['controller']
