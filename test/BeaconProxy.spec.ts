import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer } from 'ethers';

describe('Beacon Proxy', () => {
  let DummyTemplate: Contract;
  let DummyTemplateAddr: string;
  let RevertDummyMock: Contract;
  let RevertDummyAddr: string;

  let DummyDeployerMock: Contract;
  let RevertDeployerMock: Contract;

  let wallet: Signer;
  let Dummy: Signer;

  const seedPhrase = 'Beacon Test🚏';

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, Dummy] = accounts;

    // 더미 배포
    DummyTemplate = await (
      await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
    ).deploy();

    // 무조건 취소되는 더미 배포
    RevertDummyMock = await (
      await ethers.getContractFactory('contracts/mocks/RevertDummyMock.sol:RevertDummyMock', wallet)
    ).deploy();

    // 각각 비콘 배포
    const DummyTemplateTMP = await (
      await ethers.getContractFactory('contracts/mocks/BeaconMock.sol:BeaconMock', wallet)
    ).deploy();
    await DummyTemplateTMP.deploy(DummyTemplate.address);
    DummyTemplateAddr = await DummyTemplateTMP.deployedAddr();

    const RevertDummyTMP = await (
      await ethers.getContractFactory('contracts/mocks/BeaconMock.sol:BeaconMock', wallet)
    ).deploy();
    await RevertDummyTMP.deploy(RevertDummyMock.address);
    RevertDummyAddr = await RevertDummyTMP.deployedAddr();

    // 대상을 비콘에 연결
    const BeaconDeployerMockDeployer = await ethers.getContractFactory(
      'contracts/mocks/BeaconDeployerMock.sol:BeaconDeployerMock',
      wallet,
    );
    DummyDeployerMock = await BeaconDeployerMockDeployer.deploy(DummyTemplateAddr, seedPhrase);
    RevertDeployerMock = await BeaconDeployerMockDeployer.deploy(RevertDummyAddr, seedPhrase);
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
