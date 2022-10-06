import { HardhatUserConfig } from 'hardhat/config'
import '@nomiclabs/hardhat-ethers'
import 'hardhat-deploy'
import dotenv from 'dotenv'

dotenv.config()

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.17',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    }
  },
  networks: {
    hardhat: {
      live: false,
      saveDeployments: true,
      hardfork: 'arrowGlacier',
      chainId: 31337,
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`,
      },
      initialBaseFeePerGas: 0,
      accounts: [{
        balance: '100000000000000000000000',
        address: '0x8626f6940e2eb28930efb4cef49b2d1f2c9c1199',
        privateKey: '0xdf57089febbacf7ba0bc227dafbffa9fc08a93fdc68e1e42411a14efcf23656e',
      }],
    },
    localhost: {
      url: 'http://127.0.0.1:8545',
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    verificationAddress: {
      31337: 0,
    },
  },
  verify: {
    etherscan: {
      apiKey: process.env.ETHERSCAN_API_KEY,
    },
  },
  paths: {
    sources: './hardhat/contracts',
    cache: './hardhat/cache',
    artifacts: "./hardhat/artifacts",
    test: "./hardhat/test",
    deploy: './hardhat/deploy',
    deployments: './hardhat/deployments',
    imports: './hardhat/imports'
  },
}

export default config
