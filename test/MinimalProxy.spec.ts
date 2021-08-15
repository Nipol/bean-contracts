import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer } from 'ethers';

describe('Minimal Proxy', () => {
  let DummyTemplate: Contract;
  let MinimalDeployerMock: Contract;

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

    const MinimalDeployerMockDeployer = await ethers.getContractFactory(
      'contracts/mocks/MinimalDeployerMock.sol:MinimalDeployerMock',
      wallet,
    );
    MinimalDeployerMock = await MinimalDeployerMockDeployer.deploy(DummyTemplate.address, seedPhrase);

    await MinimalDeployerMock.deployed();
  });

  describe('#deploy()', () => {
    it('should be success', async () => {
      const deployaddr = await MinimalDeployerMock.deployCalculate('sample');
      await MinimalDeployerMock.deploy('sample');
      const deployed = (
        await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
      ).attach(deployaddr);
      expect(await deployed.name()).to.equal('sample');
    });
  });

  describe('#deployFromSeed()', () => {
    it('should be success', async () => {
      const deployaddr = await MinimalDeployerMock.deployCalculateFromSeed('sample');
      await MinimalDeployerMock.deployFromSeed('sample');
      const deployed = (
        await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
      ).attach(deployaddr);
      expect(await deployed.name()).to.equal('sample');
    });
  });

  describe('#isMinimal()', () => {
    it('should be success with detect beacon contract', async () => {
      const deployaddr = await MinimalDeployerMock.deployCalculateFromSeed('sample');
      await MinimalDeployerMock.deployFromSeed('sample');
      expect(await MinimalDeployerMock.isMinimal(deployaddr)).to.equal(true);
    });

    it('should be success with detect dummy contract', async () => {
      expect(await MinimalDeployerMock.isMinimal(DummyTemplate.address)).to.equal(false);
    });
  });
});
