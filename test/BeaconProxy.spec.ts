import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer } from 'ethers';

describe('Beacon Proxy', () => {
  let DummyTemplate: Contract;
  let RevertDummyMock: Contract;
  let DummyDeployerMock: Contract;
  let RevertDeployerMock: Contract;

  let wallet: Signer;
  let Dummy: Signer;

  const seedPhrase = 'Beacon Test🚏';

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, Dummy] = accounts;

    // 더미 배포
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

    // 비콘 배포
    const BeaconDeployer = await ethers.getContractFactory('contracts/library/Beacon.sol:Beacon', wallet);
    DummyTemplate = await BeaconDeployer.deploy(DummyTemplate.address);
    RevertDummyMock = await BeaconDeployer.deploy(RevertDummyMock.address);

    // 대상을 비콘에 연결
    const BeaconDeployerMockDeployer = await ethers.getContractFactory(
      'contracts/mocks/BeaconDeployerMock.sol:BeaconDeployerMock',
      wallet,
    );
    DummyDeployerMock = await BeaconDeployerMockDeployer.deploy(DummyTemplate.address, seedPhrase);
    RevertDeployerMock = await BeaconDeployerMockDeployer.deploy(RevertDummyMock.address, seedPhrase);
  });

  describe('#deploy()', () => {
    it('should be success', async () => {
      const deployaddr = await DummyDeployerMock['deployCalculate()']();
      await DummyDeployerMock['deploy()']();
      const deployed = (
        await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
      ).attach(deployaddr);
      expect(await deployed.name()).to.equal('');
    });

    it('should be unique deploy', async () => {
      await DummyDeployerMock['deploy()']();
      const deployaddr = await DummyDeployerMock['deployCalculate()']();
      await DummyDeployerMock['deploy()']();
      const deployed = (
        await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
      ).attach(deployaddr);
      expect(await deployed.name()).to.equal('');
    });
  });

  describe('#deploy initial calldata()', () => {
    it('should be success', async () => {
      const deployaddr = await DummyDeployerMock['deployCalculate(string)']('sample');
      await DummyDeployerMock['deploy(string)']('sample');
      const deployed = (
        await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
      ).attach(deployaddr);
      expect(await deployed.name()).to.equal('sample');
    });

    it('should be revert with false call', async () => {
      await expect(RevertDeployerMock['deploy(string)']('sample')).revertedWith('Intentional REVERT');
    });
  });

  describe('#deploy(seed)', () => {
    it('should be success', async () => {
      const deployaddr = await DummyDeployerMock['deployCalculateFromSeed()']();
      await DummyDeployerMock['deployFromSeed()']();
      const deployed = (
        await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
      ).attach(deployaddr);
      expect(await deployed.name()).to.equal('');
    });
  });

  describe('#deploy initial calldata (seed)', () => {
    it('should be success', async () => {
      const deployaddr = await DummyDeployerMock['deployCalculateFromSeed(string)']('sample');
      await DummyDeployerMock['deployFromSeed(string)']('sample');
      const deployed = (
        await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
      ).attach(deployaddr);
      expect(await deployed.name()).to.equal('sample');
    });

    it('should be revert with false call', async () => {
      await expect(RevertDeployerMock['deployFromSeed(string)']('sample')).revertedWith('Intentional REVERT');
    });
  });

  describe('#isBeacon()', () => {
    it('should be success with detect beacon contract', async () => {
      const deployaddr = await DummyDeployerMock['deployCalculateFromSeed(string)']('sample');
      await DummyDeployerMock['deployFromSeed(string)']('sample');
      expect(await DummyDeployerMock.isBeacon(deployaddr)).to.equal(true);
    });

    it('should be success with detect dummy contract', async () => {
      expect(await DummyDeployerMock.isBeacon(DummyTemplate.address)).to.equal(false);
    });
  });
});
