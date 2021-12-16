import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer, ContractFactory } from 'ethers';

describe('Initializer', () => {
  let AddressMock: Contract;

  let wallet: Signer;
  let Dummy: Signer;

  let ConstrucDeploy: ContractFactory;
  let InitFuncDeploy: ContractFactory;

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, Dummy] = accounts;

    ConstrucDeploy = await ethers.getContractFactory(
      'contracts/mocks/InitConstructorMock.sol:InitConstructorMock',
      wallet,
    );
    InitFuncDeploy = await ethers.getContractFactory('contracts/mocks/InitMock.sol:InitMock', wallet);
  });

  describe('#Constructor Init()', () => {
    it('should be auto initialized', async () => {
      const addr = await ConstrucDeploy.deploy();
      await expect(addr.initialize()).revertedWith('Initializer/Already Initialized');
    });
  });

  describe('#Function Init()', () => {
    it('should be auto initialized', async () => {
      const addr = await InitFuncDeploy.deploy();
      await addr.initialize();
      await expect(addr.initialize()).revertedWith('Initializer/Already Initialized');
    });
  });
});
