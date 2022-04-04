import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer } from 'ethers';
import { computeCreateAddress } from './utils';
import { Interface } from 'ethers/lib/utils';

describe('Beacon Proxy', () => {
  let DummyTemplate: Contract;
  let DummyTemplateAddr: string;
  let RevertDummyMock: Contract;
  let RevertDummyAddr: string;

  let DummyDeployerMock: Contract;
  let RevertDeployerMock: Contract;

  let wallet: Signer;
  let Dummy: Signer;

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
    const BeaconProxyMockDeployer = await ethers.getContractFactory(
      'contracts/mocks/BeaconProxyMock.sol:BeaconProxyMock',
      wallet,
    );
    DummyDeployerMock = await BeaconProxyMockDeployer.deploy(DummyTemplateAddr);
    RevertDeployerMock = await BeaconProxyMockDeployer.deploy(RevertDummyAddr);
  });

  describe('#deploy()', () => {
    it('should be success with create', async () => {
      const deployaddr = await computeCreateAddress(DummyDeployerMock.address);
      await DummyDeployerMock['deploy(bytes32)']('0x0000000000000000000000000000000000000000000000000000000000000000');
      const deployed = (
        await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
      ).attach(deployaddr);
      expect(await deployed.name()).to.equal('');
    });

    it('should be revert with same seed', async () => {
      const seed = '0x1000000000000000000000000000000000000000000000000000000000000000';
      await DummyDeployerMock['deploy(bytes32)'](seed);
      await expect(DummyDeployerMock['deploy(bytes32)'](seed)).reverted;
    });

    it('should be success after deploy initial call', async () => {
      const ABI = ['function initialize(string)'];
      const interfaces = new Interface(ABI);
      const initialize = interfaces.encodeFunctionData('initialize', ['sample']);

      const deployaddr = await computeCreateAddress(DummyDeployerMock.address);
      await DummyDeployerMock['deploy(bytes,bytes32)'](
        initialize,
        '0x0000000000000000000000000000000000000000000000000000000000000000',
      );
      const deployed = (
        await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
      ).attach(deployaddr);
      expect(await deployed.name()).to.equal('sample');
    });

    it('should be success deploy with initial call', async () => {
      const deployaddr = await computeCreateAddress(DummyDeployerMock.address);
      await DummyDeployerMock['deploy(string,bytes32)'](
        'sample',
        '0x0000000000000000000000000000000000000000000000000000000000000000',
      );
      const deployed = (
        await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
      ).attach(deployaddr);
      expect(await deployed.name()).to.equal('sample');
    });

    it('should be revert with false call', async () => {
      await expect(
        RevertDeployerMock['deploy(string,bytes32)'](
          'sample',
          '0x0000000000000000000000000000000000000000000000000000000000000000',
        ),
      ).reverted;
    });
  });

  describe('#computeAddress()', () => {
    it('should be success', async () => {
      const seed1 = '0x1000000000000000000000000000000000000000000000000000000000000000';
      const seed2 = '0x2000000000000000000000000000000000000000000000000000000000000000';
      let deployaddr = await DummyDeployerMock['deployCalculate(bytes32)'](seed1);
      await DummyDeployerMock['deploy(bytes32)'](seed1);
      let deployed = (
        await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
      ).attach(deployaddr);
      expect(await deployed.name()).to.equal('');

      deployaddr = await DummyDeployerMock['deployCalculate(bytes32)'](seed2);
      await DummyDeployerMock['deploy(bytes32)'](seed2);
      deployed = (await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)).attach(
        deployaddr,
      );
      expect(await deployed.name()).to.equal('');
    });
  });

  describe('#seedSearch()', () => {
    it('should be success', async () => {
      let deployaddr = await DummyDeployerMock['calculateIncrement()']();
      await DummyDeployerMock['deployIncrement()']();
      let deployed = (
        await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
      ).attach(deployaddr['addr']);
      expect(await deployed.name()).to.equal('');

      deployaddr = await DummyDeployerMock['calculateIncrement()']();
      await DummyDeployerMock['deployIncrement()']();
      deployed = (await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)).attach(
        deployaddr['addr'],
      );
      expect(await deployed.name()).to.equal('');
    });
  });

  describe('#isBeacon()', () => {
    it('should be success check the deployed beacon', async () => {
      let deployaddr = await DummyDeployerMock['calculateIncrement()']();
      await DummyDeployerMock['deployIncrement()']();
      expect(await DummyDeployerMock['isBeacon(address)'](deployaddr['addr'])).equal(true);
    });

    it('should be success check the deployed beacon with template', async () => {
      let deployaddr = await DummyDeployerMock['calculateIncrement()']();
      await DummyDeployerMock['deployIncrement()']();
      expect(await DummyDeployerMock['isBeacon(address,address)'](DummyTemplateAddr, deployaddr['addr'])).equal(true);
    });

    it('should be success with detect dummy contract', async () => {
      expect(await DummyDeployerMock['isBeacon(address)'](DummyTemplate.address)).to.equal(false);
    });

    it('should be success with detect dummy contract with template', async () => {
      expect(await DummyDeployerMock['isBeacon(address,address)'](DummyTemplateAddr, DummyTemplate.address)).to.equal(
        false,
      );
    });
  });
});
