import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer, ContractFactory } from 'ethers';

enum ERC173Errors {
  NOT_AUTHORIZED = 'ERC173__NotAuthorized',
  NOT_ALLOWED = 'ERC173__NotAllowedTo',
  ASSERT = '0x1',
  ARITHMETIC_OVERFLOW_OR_UNDERFLOW = '0x11',
  DIVISION_BY_ZERO = '0x12',
}

describe('Ownership', () => {
  let InitializeDeployer: ContractFactory;

  let OwnershipMockConstruct: Contract;
  let OwnershipMockInitialize: Contract;
  let MinimalProxyMock: Contract;

  let wallet: Signer;
  let Dummy1: Signer;
  let Dummy2: Signer;

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, Dummy1, Dummy2] = accounts;

    // constructor로 초기화 되는 컨트랙트 템플릿
    OwnershipMockConstruct = await (
      await ethers.getContractFactory('contracts/mocks/OwnershipMock.sol:OwnershipMock1', wallet)
    ).deploy();

    // initialize 함수로 초기화 되는 컨트랙트 템플릿
    InitializeDeployer = await ethers.getContractFactory('contracts/mocks/OwnershipMock.sol:OwnershipMock2', wallet);
    const MockInitialize = await InitializeDeployer.deploy();

    // Proxy 환경에서 작동하는지 파악하기 위한 initialize 템플릿 등록
    MinimalProxyMock = await (
      await ethers.getContractFactory('contracts/mocks/MinimalProxyMock.sol:MinimalProxyMock', wallet)
    ).deploy(MockInitialize.address);
  });

  describe('#onlyOwner modifier', () => {
    it('should be success constructor contract', async () => {
      await expect(OwnershipMockConstruct.trigger()).to.emit(OwnershipMockConstruct, 'Sample');
    });

    it('should be revert with non-owner constructor contract', async () => {
      await expect(OwnershipMockConstruct.connect(Dummy1).trigger()).revertedWith(ERC173Errors.NOT_AUTHORIZED);
    });

    it('should be success non-constructor contract', async () => {
      const addr = await wallet.getAddress();
      // 자동으로 주소가 겹치지 않게 배포되도록 (seed, address로 받아옴)
      const deployaddr = (await MinimalProxyMock.calculateIncrement())[1];
      await MinimalProxyMock.deployIncrement();
      OwnershipMockInitialize = InitializeDeployer.attach(deployaddr);
      await expect(OwnershipMockInitialize.initialize())
        .to.emit(OwnershipMockInitialize, 'OwnershipTransferred')
        .withArgs(constants.AddressZero, addr);
      await expect(OwnershipMockInitialize.trigger()).to.emit(OwnershipMockInitialize, 'Sample');
      expect(await OwnershipMockInitialize.owner()).to.equal(addr);
    });

    it('should be revert with non-owner non-constructor contract', async () => {
      const addr = await wallet.getAddress();
      const deployaddr = (await MinimalProxyMock.calculateIncrement())[1];
      await MinimalProxyMock.deployIncrement();
      OwnershipMockInitialize = InitializeDeployer.attach(deployaddr);
      await expect(OwnershipMockInitialize.initialize())
        .to.emit(OwnershipMockInitialize, 'OwnershipTransferred')
        .withArgs(constants.AddressZero, addr);
      await expect(OwnershipMockInitialize.connect(Dummy1).trigger()).revertedWith(ERC173Errors.NOT_AUTHORIZED);
      expect(await OwnershipMockInitialize.owner()).to.equal(addr);
    });
  });

  describe('#transferOwnership()', () => {
    it('should be revert with zero address from constructor contract', async () => {
      await expect(OwnershipMockConstruct.transferOwnership(constants.AddressZero)).revertedWith(
        ERC173Errors.NOT_ALLOWED,
      );
    });

    it('should be revert with zero address from non-constructor contract', async () => {
      const addr = await wallet.getAddress();
      const deployaddr = (await MinimalProxyMock.calculateIncrement())[1];
      await MinimalProxyMock.deployIncrement();
      OwnershipMockInitialize = InitializeDeployer.attach(deployaddr);
      await expect(OwnershipMockInitialize.initialize())
        .to.emit(OwnershipMockInitialize, 'OwnershipTransferred')
        .withArgs(constants.AddressZero, addr);
      await expect(OwnershipMockInitialize.transferOwnership(constants.AddressZero)).revertedWith(
        ERC173Errors.NOT_ALLOWED,
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
      await expect(OwnershipMockConstruct.resignOwnership()).revertedWith(ERC173Errors.NOT_AUTHORIZED);
    });

    it('should be success from non-constructor contract', async () => {
      const addr = await wallet.getAddress();
      const deployaddr = (await MinimalProxyMock.calculateIncrement())[1];
      await MinimalProxyMock.deployIncrement();
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
      const deployaddr = (await MinimalProxyMock.calculateIncrement())[1];
      await MinimalProxyMock.deployIncrement();
      OwnershipMockInitialize = InitializeDeployer.attach(deployaddr);
      await expect(OwnershipMockInitialize.initialize())
        .to.emit(OwnershipMockInitialize, 'OwnershipTransferred')
        .withArgs(constants.AddressZero, addr);
      await expect(OwnershipMockInitialize.resignOwnership())
        .to.emit(OwnershipMockInitialize, 'OwnershipTransferred')
        .withArgs(addr, constants.AddressZero);
      await expect(OwnershipMockInitialize.resignOwnership()).revertedWith(ERC173Errors.NOT_AUTHORIZED);
    });
  });
});
