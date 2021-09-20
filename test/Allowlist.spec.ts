import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer } from 'ethers';

describe('Allowlist', () => {
  let Allowlist: Contract;

  let wallet: Signer;
  let Dummy1: Signer;
  let Dummy2: Signer;

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, Dummy1, Dummy2] = accounts;

    const AllowlistDeployer = await ethers.getContractFactory('contracts/library/Allowlist.sol:Allowlist', wallet);
    Allowlist = await AllowlistDeployer.deploy();

    await Allowlist.deployed();
  });

  describe('#authorise()', () => {
    it('should be success authorise address', async () => {
      const addr = await Dummy1.getAddress();
      await expect(Allowlist.authorise(addr)).to.emit(Allowlist, 'Allowed').withArgs(addr);
    });

    it('should be revert with already authorized address', async () => {
      const addr = await Dummy1.getAddress();
      await expect(Allowlist.authorise(addr)).to.emit(Allowlist, 'Allowed').withArgs(addr);
      await expect(Allowlist.authorise(addr)).revertedWith('Allowlist/Already-Authorized');
    });

    it('should be reverted from not owner', async () => {
      const addr = await Dummy1.getAddress();
      await expect(Allowlist.connect(Dummy1).authorise(addr)).revertedWith('Ownership/Not-Authorized');
    });
  });

  describe('#revoke()', () => {
    it('should be success revoke registered address', async () => {
      const addr = await Dummy1.getAddress();
      await expect(Allowlist.authorise(addr)).to.emit(Allowlist, 'Allowed').withArgs(addr);
      await expect(Allowlist.revoke(addr)).to.emit(Allowlist, 'Revoked').withArgs(addr);
    });

    it('should be none-existed revoke delete', async () => {
      const addr = await Dummy1.getAddress();
      await expect(Allowlist.revoke(addr)).revertedWith('Allowlist/Not-Authorized');
    });

    it('should be reverted from not owner', async () => {
      const addr = await Dummy1.getAddress();
      await expect(Allowlist.connect(Dummy1).revoke(addr)).revertedWith('Ownership/Not-Authorized');
    });
  });
});
