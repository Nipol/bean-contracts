import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer, ContractFactory } from 'ethers';

describe('Ownership', () => {
  let InitializeDeployer: ContractFactory;

  let OwnershipMockConstruct: Contract;
  let OwnershipMockInitialize: Contract;
  let MinimalDeployerMock: Contract;

  let wallet: Signer;
  let Dummy1: Signer;
  let Dummy2: Signer;

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, Dummy1, Dummy2] = accounts;

    const ConstructDeployer = await ethers.getContractFactory(
      'contracts/mocks/OwnershipMock.sol:OwnershipMock1',
      wallet,
    );
    InitializeDeployer = await ethers.getContractFactory('contracts/mocks/OwnershipMock.sol:OwnershipMock2', wallet);
    OwnershipMockConstruct = await ConstructDeployer.deploy();
    const MockInitialize = await InitializeDeployer.deploy();

    const MinimalDeployerMockDeployer = await ethers.getContractFactory(
      'contracts/mocks/MinimalDeployerMock.sol:MinimalDeployerMock',
      wallet,
    );
    MinimalDeployerMock = await MinimalDeployerMockDeployer.deploy(MockInitialize.address, '');
  });

  describe('#onlyOwner modifier', () => {
    it('should be success constructor contract', async () => {
      await expect(OwnershipMockConstruct.trigger()).to.emit(OwnershipMockConstruct, 'Sample');
    });

    it('should be revert with non-owner constructor contract', async () => {
      await expect(OwnershipMockConstruct.connect(Dummy1).trigger()).revertedWith('Ownership/Not-Authorized');
    });

    it('should be success non-constructor contract', async () => {
      const addr = await wallet.getAddress();
      const deployaddr = await MinimalDeployerMock['deployCalculate()']();
      await MinimalDeployerMock['deploy()']();
      OwnershipMockInitialize = InitializeDeployer.attach(deployaddr);
      await expect(OwnershipMockInitialize.initialize())
        .to.emit(OwnershipMockInitialize, 'OwnershipTransferred')
        .withArgs(constants.AddressZero, addr);
      await expect(OwnershipMockInitialize.trigger()).to.emit(OwnershipMockInitialize, 'Sample');
      expect(await OwnershipMockInitialize.owner()).to.equal(addr);
    });

    it('should be revert with non-owner non-constructor contract', async () => {
      const addr = await wallet.getAddress();
      const deployaddr = await MinimalDeployerMock['deployCalculate()']();
      await MinimalDeployerMock['deploy()']();
      OwnershipMockInitialize = InitializeDeployer.attach(deployaddr);
      await expect(OwnershipMockInitialize.initialize())
        .to.emit(OwnershipMockInitialize, 'OwnershipTransferred')
        .withArgs(constants.AddressZero, addr);
      await expect(OwnershipMockInitialize.connect(Dummy1).trigger()).revertedWith('Ownership/Not-Authorized');
      expect(await OwnershipMockInitialize.owner()).to.equal(addr);
    });
  });

  describe('#transferOwnership()', () => {
    it('should be revert with zero address from constructor contract', async () => {
      await expect(OwnershipMockConstruct.transferOwnership(constants.AddressZero)).revertedWith(
        'Ownership/Not-Allowed-Zero',
      );
    });

    it('should be revert with zero address from non-constructor contract', async () => {
      const addr = await wallet.getAddress();
      const deployaddr = await MinimalDeployerMock['deployCalculate()']();
      await MinimalDeployerMock['deploy()']();
      OwnershipMockInitialize = InitializeDeployer.attach(deployaddr);
      await expect(OwnershipMockInitialize.initialize())
        .to.emit(OwnershipMockInitialize, 'OwnershipTransferred')
        .withArgs(constants.AddressZero, addr);
      await expect(OwnershipMockInitialize.transferOwnership(constants.AddressZero)).revertedWith(
        'Ownership/Not-Allowed-Zero',
      );
      expect(await OwnershipMockInitialize.owner()).to.equal(addr);
    });

    it('should be success from constructor contract', async () => {
      const prev = await wallet.getAddress();
      const addr = await Dummy1.getAddress();
      await expect(OwnershipMockConstruct.transferOwnership(addr))
        .to.emit(OwnershipMockConstruct, 'OwnershipTransferred')
        .withArgs(prev, addr);
      expect(await OwnershipMockConstruct.owner()).to.equal(addr);
    });
  });

  describe('#resignOwnership()', () => {
    it('should be success from constructor contract', async () => {
      const prev = await wallet.getAddress();
      await expect(OwnershipMockConstruct.resignOwnership())
        .to.emit(OwnershipMockConstruct, 'OwnershipTransferred')
        .withArgs(prev, constants.AddressZero);
    });

    it('should be revert with non-owner from constructor contract', async () => {
      await OwnershipMockConstruct.resignOwnership();
      await expect(OwnershipMockConstruct.resignOwnership()).revertedWith('Ownership/Not-Authorized');
    });

    it('should be success from non-constructor contract', async () => {
      const addr = await wallet.getAddress();
      const deployaddr = await MinimalDeployerMock['deployCalculate()']();
      await MinimalDeployerMock['deploy()']();
      OwnershipMockInitialize = InitializeDeployer.attach(deployaddr);
      await expect(OwnershipMockInitialize.initialize())
        .to.emit(OwnershipMockInitialize, 'OwnershipTransferred')
        .withArgs(constants.AddressZero, addr);
      await expect(OwnershipMockInitialize.resignOwnership())
        .to.emit(OwnershipMockInitialize, 'OwnershipTransferred')
        .withArgs(addr, constants.AddressZero);
      expect(await OwnershipMockInitialize.owner()).to.equal(constants.AddressZero);
    });

    it('should be revert with non-owner from non-constructor contract', async () => {
      const addr = await wallet.getAddress();
      const deployaddr = await MinimalDeployerMock['deployCalculate()']();
      await MinimalDeployerMock['deploy()']();
      OwnershipMockInitialize = InitializeDeployer.attach(deployaddr);
      await expect(OwnershipMockInitialize.initialize())
        .to.emit(OwnershipMockInitialize, 'OwnershipTransferred')
        .withArgs(constants.AddressZero, addr);
      await expect(OwnershipMockInitialize.resignOwnership())
        .to.emit(OwnershipMockInitialize, 'OwnershipTransferred')
        .withArgs(addr, constants.AddressZero);
      await expect(OwnershipMockInitialize.resignOwnership()).revertedWith('Ownership/Not-Authorized');
    });
  });
});
