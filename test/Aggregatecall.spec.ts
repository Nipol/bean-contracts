import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer } from 'ethers';
import { Interface } from 'ethers/lib/utils';

type Call = {
  target: string;
  data: string;
};

describe('Aggregatecall', () => {
  let AggregatecallMock: Contract;
  let CallDummy: Contract;

  let wallet: Signer;
  let Dummy: Signer;

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, Dummy] = accounts;

    const AggregatecallMockDeployer = await ethers.getContractFactory(
      'contracts/mocks/AggregatecallMock.sol:AggregatecallMock',
      wallet,
    );
    AggregatecallMock = await AggregatecallMockDeployer.deploy();

    const CallDummyDeployer = await ethers.getContractFactory(
      'contracts/mocks/MulticallMock.sol:MulticallMock',
      wallet,
    );
    CallDummy = await CallDummyDeployer.deploy();
  });

  describe('#aggregate()', () => {
    it('should be success with multicalls', async () => {
      const ABI = [
        'function increase()',
        'function decrease()',
        'function increaseWithRevert()',
        'function decreaseWithRevert()',
        'function whatEver()',
      ];
      const interfaces = new Interface(ABI);
      const increase = interfaces.encodeFunctionData('increase');
      const decrease = interfaces.encodeFunctionData('decrease');

      const calls: Call[] = [increase, increase, increase, decrease].map(element => ({
        target: CallDummy.address,
        data: element,
      }));

      await AggregatecallMock.aggregate(calls);

      expect(await CallDummy.stage()).to.equal('2');
    });

    it('should be fail with revert', async () => {
      const ABI = [
        'function increase()',
        'function decrease()',
        'function increaseWithRevert()',
        'function decreaseWithRevert()',
        'function whatEver()',
      ];
      const interfaces = new Interface(ABI);
      const decrease = interfaces.encodeFunctionData('decrease');

      const call: Call = {
        target: CallDummy.address,
        data: decrease,
      };

      await expect(AggregatecallMock.aggregate([call])).to.be.revertedWith('');
    });

    it('should be fail with revert message', async () => {
      const ABI = [
        'function increase()',
        'function decrease()',
        'function increaseWithRevert()',
        'function decreaseWithRevert()',
        'function whatEver()',
      ];
      const interfaces = new Interface(ABI);
      const decrease = interfaces.encodeFunctionData('decreaseWithRevert');

      const call: Call = {
        target: CallDummy.address,
        data: decrease,
      };

      await expect(AggregatecallMock.aggregate([call])).to.be.revertedWith('decrease');
    });
  });
});
