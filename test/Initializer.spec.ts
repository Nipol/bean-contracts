import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer, ContractFactory } from 'ethers';

enum InitializerErrors {
  ALREADY_INITIALIZED = 'AlreadyInitialized',
}

describe('Initializer', () => {
  let wallet: Signer;
  let Dummy: Signer;

  let ConstrucDeploy: ContractFactory;
  let Init: Contract;

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, Dummy] = accounts;

    ConstrucDeploy = await ethers.getContractFactory(
      'contracts/mocks/InitConstructorMock.sol:InitConstructorMock',
      wallet,
    );
    Init = await (await ethers.getContractFactory('contracts/mocks/InitMock.sol:InitMock', wallet)).deploy();
  });

  describe('construct auto initializer', () => {
    it('should be success with construct with auto initialize', async () => {
      await expect(Init.initialize()).revertedWith(InitializerErrors.ALREADY_INITIALIZED);
    });

    it('should be not initialize contract using initialized contract', async () => {
      const proxyDeployer = await (
        await ethers.getContractFactory('contracts/mocks/MinimalProxyMock.sol:MinimalProxyMock', wallet)
      ).deploy(Init.address);

      const deployable = (await proxyDeployer.calculateIncrement())['addr'];

      await proxyDeployer.deployIncrement();

      const deployed = (await ethers.getContractFactory('contracts/mocks/InitMock.sol:InitMock', wallet)).attach(
        deployable,
      );

      await deployed.initialize();
      await expect(deployed.initialize()).revertedWith(InitializerErrors.ALREADY_INITIALIZED);
    });
  });

  describe('#modifier initializer()', () => {
    it('should be auto initialized', async () => {
      const addr = await ConstrucDeploy.deploy();
      await expect(addr.initialize()).revertedWith(InitializerErrors.ALREADY_INITIALIZED);
    });
  });
});
