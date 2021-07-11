import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer } from 'ethers';
import {Interface} from 'ethers/lib/utils';

describe('Multicall', () => {
  let MulticallMock: Contract;

  let wallet: Signer;
  let Dummy: Signer;

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, Dummy] = accounts;

    const MulticallMockDeployer = await ethers.getContractFactory('contracts/mocks/MulticallMock.sol:MulticallMock', wallet);
    MulticallMock = await MulticallMockDeployer.deploy();

    await MulticallMock.deployed();
  });

  describe('#multicall()', () => {
    it('should be success with multicalls', async () => {
        const ABI = [
            'function increase()',
            'function decrease()',
            'function increaseWithLongMessage()',
            'function decreaseWithLongMessage()'
          ];
        const interfaces = new Interface(ABI);

        const increase = interfaces.encodeFunctionData('increase');
        const decrease = interfaces.encodeFunctionData('decrease');

        await MulticallMock.multicall([increase,increase,increase,decrease]);

        expect(await MulticallMock.stage()).to.equal("2");
    });

    it('should be true from Contract', async () => {
      });
  });
});