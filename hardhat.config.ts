import { task } from 'hardhat/config';
import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-solhint';
import 'hardhat-gas-reporter';
import 'solidity-coverage';

task('accounts', 'Prints the list of accounts', async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log('address: ' + (await account.getAddress()));
  }
});

// "m/44'/1'/0'/0"
// "test test test test test test test test test test test junk"
const accounts = [
  {
    //0x22310Bf73bC88ae2D2c9a29Bd87bC38FBAc9e6b0
    privateKey: '0x7c299dda7c704f9d474b6ca5d7fee0b490c8decca493b5764541fe5ec6b65114',
    balance: '10000000000000000000000',
  },
  {
    //0x5AEC774E6ae749DBB17A2EBA03648207A5bd7dDd
    privateKey: '0x50064dccbc8b9d9153e340ee2759b0fc4936ffe70cb451dad5563754d33c34a8',
    balance: '10000000000000000000000',
  },
  {
    //0xb6857B2E965cFc4B7394c52df05F5E93a9e4e0Dd
    privateKey: '0x95c674cabc4b9885d930d2c0f592fdde8dc24b4e6a43ae05c6ada58edb9f54ae',
    balance: '10000000000000000000000',
  },
  {
    //0x2E1eD4eEd20c338378800d8383a54E3329957c3d
    privateKey: '0x24af27ccb29738cdaba736d8e35cb4d43ace56e1c83389f48feb746b38cf2a05',
    balance: '10000000000000000000000',
  },
  {
    //0x7DC241C040A66542139890Ff7872824f5440aFD3
    privateKey: '0xb21deff810a52cded6c3f9a0f57184f1c70ff08cc3097bec420aa39c7693ed8c',
    balance: '10000000000000000000000',
  },
];

export default {
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {
      gas: 9000000,
      blockGasLimit: 15000000,
      accounts,
    },
    coverage: {
      url: 'http://localhost:8555',
    },
    // ropsten: {
    //   url: `https://${process.env.RIVET_KEY}.ropsten.rpc.rivet.cloud/`,
    //   accounts: [`${process.env.DEPLOYER_PK}`],
    //   gasPrice: 8000000000,
    //   timeout: 500000
    // },
    // goerli: {
    //   url: `https://${process.env.RIVET_KEY}.goerli.rpc.rivet.cloud/`,
    //   accounts: [`${process.env.DEPLOYER_PK}`],
    //   gasPrice: 8000000000,
    //   timeout: 500000
    // }
  },
  solidity: {
    version: '0.8.6',
    settings: {
      optimizer: {
        enabled: true,
        runs: 9999999,
        details: {
          yul: true,
        },
      },
    },
  },
  paths: {
    sources: './contracts',
    tests: './test',
    cache: './cache',
    artifacts: './artifacts',
  },
  gasReporter: {
    currency: 'USD',
    gasPrice: 40,
  },
};
