import { task, subtask, HardhatUserConfig } from 'hardhat/config';
import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-solhint';
import 'hardhat-gas-reporter';
import 'solidity-coverage';

const mnemonic: string = 'test test test test test test test test test test test junk';

const { TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS } = require('hardhat/builtin-tasks/task-names');
subtask(TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS).setAction(async (_, __, runSuper) => {
  const paths = await runSuper();

  return paths.filter((p: any) => !p.endsWith('.t.sol'));
});

task('accounts', 'Prints the list of accounts', async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log('address: ' + (await account.getAddress()));
  }
});

const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',

  gasReporter: {
    currency: 'USD',
    gasPrice: 30,
  },

  networks: {
    localhost: {
      url: 'http://localhost:8545',
    },
    hardhat: {
      accounts: {
        mnemonic,
        path: "m/44'/1'/0'/0",
      },
    },
    coverage: {
      url: 'http://localhost:8555',
    },
  },

  solidity: {
    compilers: [
      {
        version: '0.8.13',
        settings: {
          optimizer: {
            enabled: true,
            runs: 42069,
            details: {
              yul: true,
            },
          },
        },
      },
    ],
  },

  paths: {
    sources: './contracts',
    tests: './test',
    cache: './hh-cache',
    artifacts: './artifacts',
  },

  mocha: {
    timeout: 0,
  },
};

export default config;
