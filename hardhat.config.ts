import { HardhatUserConfig } from 'hardhat/config'
import '@nomiclabs/hardhat-ethers'
import 'hardhat-deploy'
import dotenv from 'dotenv'

dotenv.config()
const NULL_PRIVATE_KEY = '0x000000000000000000000000000000000000000000000000000000000000DEAD'

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
    mumbai: {
      url: 'https://rpc-mumbai.maticvigil.com',
      // gasPrice: 30000000000,  // gwei
      accounts: [
        process.env.TESTNET_DEPLOYER_PRIVATEKEY || NULL_PRIVATE_KEY,
        process.env.TESTNET_PARAMS_SIGNER_PRIVATE_KEY || NULL_PRIVATE_KEY,
      ],
    },
    mainnet: {
      url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`,
      gasPrice: 12000000000,  // gwei
      accounts: [
        process.env.MAINNET_DEPLOYER_PRIVATEKEY || NULL_PRIVATE_KEY,
        process.env.MAINNET_PARAMS_SIGNER_PRIVATE_KEY || NULL_PRIVATE_KEY,
      ],
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    paramsSigner: {
      1: 1,  // ethereum mainnet
      80001: 1,  // polygon mumbai
      31337: 0,  // localhost
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
