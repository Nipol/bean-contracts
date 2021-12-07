import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer, utils } from 'ethers';
import { Interface } from 'ethers/lib/utils';

function buf2hex(buffer: Buffer) {
  // buffer is an ArrayBuffer
  return '0x' + [...new Uint8Array(buffer)].map(x => x.toString(16).padStart(2, '0')).join('');
}

describe.only('Wizadry', () => {
  let WizadryMock: Contract;
  let TokenMock: Contract;
  let TokenLib: Contract;

  let wallet: Signer;
  let Dummy: Signer;

  const initialToken = BigNumber.from('100000000000000000000');

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, Dummy] = accounts;

    const WizadryMockDeployer = await ethers.getContractFactory('contracts/mocks/WizadryMock.sol:WizadryMock', wallet);
    WizadryMock = await WizadryMockDeployer.deploy();

    const TokenMockDeployer = await ethers.getContractFactory('contracts/mocks/TokenMock.sol:TokenMock', wallet);
    TokenMock = await TokenMockDeployer.deploy('SAMPLE', 'SMPL', '18');

    const TokenLibDeployer = await ethers.getContractFactory(
      'contracts/mocks/ERC20SpellMock.sol:ERC20SpellMock',
      wallet,
    );
    TokenLib = await TokenLibDeployer.deploy();

    await TokenMock.mintTo(WizadryMock.address, initialToken);
  });

  describe('#_cast()', () => {
    it('should be successfully transfer token', async () => {
      const ABI = ['function balanceOf(address target)', 'function transfer(address to,uint256 value)'];
      const interfaces = new Interface(ABI);
      const balanceOfsig = interfaces.getSighash('balanceOf');
      const transferSig = interfaces.getSighash('transfer');
      const elements = [
        '0x000000000000000000000000' + WizadryMock.address.slice(2), // for balanceof
        '0x000000000000000000000000' + (await Dummy.getAddress()).slice(2), // transfer
      ];

      const spells = [
        utils.concat([
          balanceOfsig, // function selector
          '0x40', // flag return value not tuple
          '0x00', // value position from elements array
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0x00',
          TokenMock.address, // address
        ]),
        utils.concat([
          transferSig, // function selector
          '0x40', // flag
          '0x01', // value position from elements array
          '0x00',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          TokenMock.address, // address
        ]),
      ];

      await WizadryMock.cast(spells, elements);
      expect(await TokenMock.balanceOf(await Dummy.getAddress())).to.equal(initialToken);
    });
  });
});
