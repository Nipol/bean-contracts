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

  describe('#modifier initializer()', () => {
    it('should be initialized', async () => {
      await Init.initialize();
      await expect(Init.initialize()).revertedWith(InitializerErrors.ALREADY_INITIALIZED);
    });

    it('should be auto initialized', async () => {
      const addr = await ConstrucDeploy.deploy();
      await expect(addr.initialize()).revertedWith(InitializerErrors.ALREADY_INITIALIZED);
    });
  });
});
