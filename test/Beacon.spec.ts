import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer } from 'ethers';

describe('Beacon', () => {
  let Beacon: Contract;

  let wallet: Signer;
  let Dummy: Signer;

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, Dummy] = accounts;

    const BeaconDeployer = await ethers.getContractFactory('contracts/library/Beacon.sol:Beacon', wallet);
    Beacon = await BeaconDeployer.deploy('0x0000000000000000000000000000000000000001');

    await Beacon.deployed();
  });

  describe('#()', () => {
    it('should be changed implementdation from Owner', async () => {
      await wallet.sendTransaction({
        to: Beacon.address,
        data: '0x0000000000000000000000000000000000000000000000000000000000000002',
      });

      expect(await Beacon.callStatic._implementation()).to.equal('0x0000000000000000000000000000000000000002');
    });

    it('should be not change implementation from non-Owner', async () => {
      await Dummy.sendTransaction({
        to: Beacon.address,
        data: '0x0000000000000000000000000000000000000000000000000000000000000002',
      });

      expect(
        await Dummy.call({
          to: Beacon.address,
        }),
      ).to.equal('0x0000000000000000000000000000000000000000000000000000000000000001');
    });
  });
});
