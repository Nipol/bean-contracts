import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer } from 'ethers';
import { Interface } from 'ethers/lib/utils';

describe('Caster', () => {
  let SpellCasterMock: Contract;
  let TokenMock: Contract;
  let TokenLib: Contract;

  let wallet: Signer;
  let Dummy: Signer;

  const initialToken = BigNumber.from('100000000000000000000');
  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, Dummy] = accounts;

    const SpellCasterMockDeployer = await ethers.getContractFactory(
      'contracts/mocks/SpellCasterMock.sol:SpellCasterMock',
      wallet,
    );
    SpellCasterMock = await SpellCasterMockDeployer.deploy();

    const TokenMockDeployer = await ethers.getContractFactory('contracts/mocks/TokenMock.sol:TokenMock', wallet);
    TokenMock = await TokenMockDeployer.deploy('SAMPLE', 'SMPL', '18');

    const TokenLibDeployer = await ethers.getContractFactory(
      'contracts/mocks/ERC20SpellMock.sol:ERC20SpellMock',
      wallet,
    );
    TokenLib = await TokenLibDeployer.deploy();

    await TokenMock.mintTo(SpellCasterMock.address, initialToken);
  });

  describe('#cast()', () => {
    it('should be Success token transfer', async () => {
      const addr = await Dummy.getAddress();
      const value = BigNumber.from('1000000000000000000');
      const ABI = ['function transfer(address ERC20,address to,uint256 value)'];
      const interfaces = new Interface(ABI);
      const data = interfaces.encodeFunctionData('transfer', [TokenMock.address, addr, value]);

      expect(await TokenMock.balanceOf(SpellCasterMock.address)).to.be.equal(initialToken);
      await SpellCasterMock.casting([TokenLib.address], [data]);
      expect(await TokenMock.balanceOf(addr)).to.be.equal(value);
      expect(await TokenMock.balanceOf(SpellCasterMock.address)).to.be.equal(initialToken.sub(value));
    });
  });
});
