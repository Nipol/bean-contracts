import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer } from 'ethers';

describe('Minimal Proxy', () => {
  let DummyTemplate: Contract;
  let RevertDummyMock: Contract;
  let MinimalDeployerMock: Contract;
  let RevertDeployerMock: Contract;

  let wallet: Signer;

  const seedPhrase = 'Minimal Test🚏';

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet] = accounts;

    const DummyTemplateDeployer = await ethers.getContractFactory(
      'contracts/mocks/DummyTemplate.sol:DummyTemplate',
      wallet,
    );
    DummyTemplate = await DummyTemplateDeployer.deploy();

    // 무조건 취소되는 더미 배포
    const RevertDummyMockDeployer = await ethers.getContractFactory(
      'contracts/mocks/RevertDummyMock.sol:RevertDummyMock',
      wallet,
    );
    RevertDummyMock = await RevertDummyMockDeployer.deploy();

    const MinimalDeployerMockDeployer = await ethers.getContractFactory(
      'contracts/mocks/MinimalDeployerMock.sol:MinimalDeployerMock',
      wallet,
    );
    MinimalDeployerMock = await MinimalDeployerMockDeployer.deploy(DummyTemplate.address, seedPhrase);
    RevertDeployerMock = await MinimalDeployerMockDeployer.deploy(RevertDummyMock.address, seedPhrase);
  });

  describe('#deploy()', () => {
    it('should be success', async () => {
      const deployaddr = await MinimalDeployerMock['deployCalculate()']();
      await MinimalDeployerMock['deploy()']();
      const deployed = (
        await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
      ).attach(deployaddr);
      expect(await deployed.name()).to.equal('');
    });

    it('should be unique deploy', async () => {
      await MinimalDeployerMock['deploy()']();
      const deployaddr = await MinimalDeployerMock['deployCalculate()']();
      await MinimalDeployerMock['deploy()']();
      const deployed = (
        await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
      ).attach(deployaddr);
      expect(await deployed.name()).to.equal('');
    });
  });

  describe('#deploy initial calldata()', () => {
    it('should be success', async () => {
      const deployaddr = await MinimalDeployerMock['deployCalculate(string)']('sample');
      await MinimalDeployerMock['deploy(string)']('sample');
      const deployed = (
        await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
      ).attach(deployaddr);
      expect(await deployed.name()).to.equal('sample');
    });

    it('should be revert from false call', async () => {
      await expect(RevertDeployerMock['deploy(string)']('sample')).revertedWith('Intentional REVERT');
    });
  });

  describe('#deploy(seed)', () => {
    it('should be success', async () => {
      const deployaddr = await MinimalDeployerMock['deployCalculateFromSeed()']();
      await MinimalDeployerMock['deployFromSeed()']();
      const deployed = (
        await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
      ).attach(deployaddr);
      expect(await deployed.name()).to.equal('');
    });
  });

  describe('#deploy initial calldata(seed)', () => {
    it('should be success', async () => {
      const deployaddr = await MinimalDeployerMock['deployCalculateFromSeed(string)']('sample');
      await MinimalDeployerMock['deployFromSeed(string)']('sample');
      const deployed = (
        await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
      ).attach(deployaddr);
      expect(await deployed.name()).to.equal('sample');
    });

    it('should be revert from false call', async () => {
      await expect(RevertDeployerMock['deployFromSeed(string)']('sample')).revertedWith('Intentional REVERT');
    });
  });

  describe('#isMinimal()', () => {
    it('should be success with detect beacon contract', async () => {
      const deployaddr = await MinimalDeployerMock['deployCalculateFromSeed(string)']('sample');
      await MinimalDeployerMock['deployFromSeed(string)']('sample');
      expect(await MinimalDeployerMock.isMinimal(deployaddr)).to.equal(true);
    });

    it('should be success with detect dummy contract', async () => {
      expect(await MinimalDeployerMock.isMinimal(DummyTemplate.address)).to.equal(false);
    });
  });
});
