import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer } from 'ethers';

describe('Minimal Proxy', () => {
  let DummyTemplate: Contract;
  let MinimalDeployerMock: Contract;

  let wallet: Signer;

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
    MinimalDeployerMock = await MinimalDeployerMockDeployer.deploy(DummyTemplate.address);

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
});
