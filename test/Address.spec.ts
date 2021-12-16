import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer } from 'ethers';

describe('Address', () => {
  let AddressMock: Contract;

  let wallet: Signer;
  let Dummy: Signer;

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, Dummy] = accounts;

    const AddressMockDeployer = await ethers.getContractFactory('contracts/mocks/AddressMock.sol:AddressMock', wallet);
    AddressMock = await AddressMockDeployer.deploy();

    await AddressMock.deployed();
  });

  describe('#isContract()', () => {
    it('should be false from EOA', async () => {
      const addr = await Dummy.getAddress();
      expect(await AddressMock.isContract(addr)).to.equal(false);
    });

    it('should be true from Contract', async () => {
      const DummyDeployer = await ethers.getContractFactory('contracts/mocks/TokenMock.sol:TokenMock', wallet);
      const DummyMock: Contract = await DummyDeployer.deploy('Sample', 'SMP', 18, '1');
      const addr = DummyMock.address;
      expect(await AddressMock.isContract(addr)).to.equal(true);
    });
  });
});
