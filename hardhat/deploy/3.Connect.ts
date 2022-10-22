import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

const func: DeployFunction = async function({
  getNamedAccounts,
  deployments,
  ethers,
}: HardhatRuntimeEnvironment) {
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const [
    MuseTime,
    MuseTimeController,
  ] = await Promise.all([
    deployments.get('MuseTime'),
    deployments.get('MuseTimeController'),
  ])

  const signer = await ethers.getSigner(deployer)
  const museTime = new ethers.Contract(MuseTime.address, MuseTime.abi, signer)
  const controllerAddress = await museTime.controller()

  if (controllerAddress === '0x0000000000000000000000000000000000000000') {
    const tx = await museTime.setController(MuseTimeController.address);
    console.log(`setController ${MuseTimeController.address}`);
    console.log(`tx: ${tx.hash}`);
    await tx.wait();
  }

}

export const tags = ['connect']

export default func
