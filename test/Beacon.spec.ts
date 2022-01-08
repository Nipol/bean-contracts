import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer } from 'ethers';

describe('Beacon', () => {
  let BeaconMock: Contract;

  let wallet: Signer;
  let Dummy: Signer;

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, Dummy] = accounts;

    BeaconMock = await (await ethers.getContractFactory('contracts/mocks/BeaconMock.sol:BeaconMock', wallet)).deploy();
  });

  describe('#()', () => {
    it('should be changed implementdation from Owner', async () => {
      await BeaconMock.deploy('0x0000000000000000000000000000000000000001');
      const deployedAddr = await BeaconMock.deployedAddr();
      await BeaconMock.changeImplementation('0x0000000000000000000000000000000000000002');

      expect(
        await Dummy.call({
          to: deployedAddr,
        }),
      ).to.equal('0x0000000000000000000000000000000000000000000000000000000000000002');
    });

    it('should be not change implementation from non-Owner', async () => {
      await BeaconMock.deploy('0x0000000000000000000000000000000000000001');
      const deployedAddr = await BeaconMock.deployedAddr();

      await Dummy.sendTransaction({
        to: deployedAddr,
        data: '0x0000000000000000000000000000000000000000000000000000000000000002',
      });

      expect(
        await Dummy.call({
          to: deployedAddr,
        }),
      ).to.equal('0x0000000000000000000000000000000000000000000000000000000000000001');
    });
  });
});
