import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer } from 'ethers';
import { computeCreateAddress } from './utils';
import { Interface } from 'ethers/lib/utils';

describe('Minimal Proxy', () => {
  let DummyTemplate: Contract;
  let RevertDummyMock: Contract;
  let MinimalProxyMock: Contract;
  let RevertProxyMock: Contract;

  let wallet: Signer;

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet] = accounts;

    // 일반적인 더미
    DummyTemplate = await (
      await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
    ).deploy();

    // 무조건 취소되는 더미 배포
    RevertDummyMock = await (
      await ethers.getContractFactory('contracts/mocks/RevertDummyMock.sol:RevertDummyMock', wallet)
    ).deploy();

    MinimalProxyMock = await (
      await ethers.getContractFactory('contracts/mocks/MinimalProxyMock.sol:MinimalProxyMock', wallet)
    ).deploy(DummyTemplate.address);

    RevertProxyMock = await (
      await ethers.getContractFactory('contracts/mocks/MinimalProxyMock.sol:MinimalProxyMock', wallet)
    ).deploy(RevertDummyMock.address);
  });

  describe('#deploy()', () => {
    it('should be success with create', async () => {
      const deployaddr = await computeCreateAddress(MinimalProxyMock.address);
      await MinimalProxyMock['deploy(bytes32)']('0x0000000000000000000000000000000000000000000000000000000000000000');
      const deployed = (
        await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
      ).attach(deployaddr);
      expect(await deployed.name()).to.equal('');
    });

    it('should be revert with same seed', async () => {
      const seed = '0x1000000000000000000000000000000000000000000000000000000000000000';
      await MinimalProxyMock['deploy(bytes32)'](seed);
      await expect(MinimalProxyMock['deploy(bytes32)'](seed)).reverted;
    });

    it('should be success after deploy initial call', async () => {
      const ABI = ['function initialize(string)'];
      const interfaces = new Interface(ABI);
      const initialize = interfaces.encodeFunctionData('initialize', ['sample']);

      const deployaddr = await computeCreateAddress(MinimalProxyMock.address);
      await MinimalProxyMock['deploy(bytes,bytes32)'](
        initialize,
        '0x0000000000000000000000000000000000000000000000000000000000000000',
      );
      const deployed = (
        await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
      ).attach(deployaddr);
      expect(await deployed.name()).to.equal('sample');
    });

    it('should be success deploy with initial call', async () => {
      const deployaddr = await computeCreateAddress(MinimalProxyMock.address);
      await MinimalProxyMock['deploy(string,bytes32)'](
        'sample',
        '0x0000000000000000000000000000000000000000000000000000000000000000',
      );
      const deployed = (
        await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
      ).attach(deployaddr);
      expect(await deployed.name()).to.equal('sample');
    });
  });

  describe('#computeAddress()', () => {
    it('should be success', async () => {
      const seed1 = '0x1000000000000000000000000000000000000000000000000000000000000000';
      const seed2 = '0x2000000000000000000000000000000000000000000000000000000000000000';
      let deployaddr = await MinimalProxyMock['deployCalculate(bytes32)'](seed1);
      await MinimalProxyMock['deploy(bytes32)'](seed1);
      let deployed = (
        await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
      ).attach(deployaddr);
      expect(await deployed.name()).to.equal('');

      deployaddr = await MinimalProxyMock['deployCalculate(bytes32)'](seed2);
      await MinimalProxyMock['deploy(bytes32)'](seed2);
      deployed = (await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)).attach(
        deployaddr,
      );
      expect(await deployed.name()).to.equal('');
    });
  });

  describe('#seedSearch()', () => {
    it('should be success', async () => {
      let deployaddr = await MinimalProxyMock['calculateIncrement()']();
      await MinimalProxyMock['deployIncrement()']();
      let deployed = (
        await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
      ).attach(deployaddr['addr']);
      expect(await deployed.name()).to.equal('');

      deployaddr = await MinimalProxyMock['calculateIncrement()']();
      await MinimalProxyMock['deployIncrement()']();
      deployed = (await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)).attach(
        deployaddr['addr'],
      );
      expect(await deployed.name()).to.equal('');
    });
  });

  describe('#isMinimal()', () => {
    it('should be success check the deployed minimal', async () => {
      let deployaddr = await MinimalProxyMock['calculateIncrement()']();
      await MinimalProxyMock['deployIncrement()']();
      expect(await MinimalProxyMock.isMinimal(deployaddr['addr'])).equal(true);
    });
  });
});
