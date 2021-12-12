import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer, utils } from 'ethers';
import { defaultAbiCoder, Interface, formatBytes32String, hexDataSlice } from 'ethers/lib/utils';

function buf2hex(buffer: Buffer) {
  // buffer is an ArrayBuffer
  return '0x' + [...new Uint8Array(buffer)].map(x => x.toString(16).padStart(2, '0')).join('');
}

describe.only('Wizadry', () => {
  let WizadryMock: Contract;
  let TokenMock: Contract;
  let TokenLib: Contract;
  let StringLib: Contract;
  let VaultMock: Contract;
  let EventLib: Contract;

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

    const VaultMockDeployer = await ethers.getContractFactory('contracts/mocks/VaultMock.sol:VaultMock', wallet);
    VaultMock = await VaultMockDeployer.deploy();

    const EventMockDeployer = await ethers.getContractFactory('contracts/mocks/EventMock.sol:EventMock', wallet);
    EventLib = await EventMockDeployer.deploy();

    const StringSpellMockDeployer = await ethers.getContractFactory(
      'contracts/mocks/StringSpellMock.sol:StringSpellMock',
      wallet,
    );
    StringLib = await StringSpellMockDeployer.deploy();

    const TokenLibDeployer = await ethers.getContractFactory(
      'contracts/mocks/ERC20SpellMock.sol:ERC20SpellMock',
      wallet,
    );
    TokenLib = await TokenLibDeployer.deploy();

    await TokenMock.mintTo(WizadryMock.address, initialToken);
  });

  describe('#cast()', () => {
    it('should be successfully transfer token with call', async () => {
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

      await WizadryMock._cast(spells, elements);
      expect(await TokenMock.balanceOf(await Dummy.getAddress())).to.equal(initialToken);
    });

    it('should be successfully transfer token with delegatecall', async () => {
      const ABI = [
        'function balanceOf(address ERC20,address target)',
        'function transfer(address ERC20,address to,uint256 value)',
      ];
      const interfaces = new Interface(ABI);
      const balanceOfsig = interfaces.getSighash('balanceOf');
      const transferSig = interfaces.getSighash('transfer');
      const elements = [
        '0x000000000000000000000000' + TokenMock.address.slice(2), // tokenlib
        '0x000000000000000000000000' + WizadryMock.address.slice(2), // for balanceof
        '0x000000000000000000000000' + (await Dummy.getAddress()).slice(2), // transfer
      ];

      const spells = [
        utils.concat([
          balanceOfsig, // function selector from address
          '0x00', // flag return value not tuple
          '0x00', // value position from elements array
          '0x01',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0x01', // returned data position
          TokenLib.address, // address
        ]),
        utils.concat([
          transferSig, // function selector from address
          '0x00', // flag
          '0x00', // value position from elements array
          '0x02',
          '0x01',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF', // returned data position
          TokenLib.address, // address
        ]),
      ];

      await WizadryMock._cast(spells, elements);
      expect(await TokenMock.balanceOf(await Dummy.getAddress())).to.equal(initialToken);
    });

    it('should be successfully function with value call', async () => {
      await wallet.sendTransaction({
        to: WizadryMock.address,
        value: ethers.utils.parseEther('1.0'), // Sends exactly 1.0 ether
      });

      const ABI = ['function save()'];
      const interfaces = new Interface(ABI);
      const saveSig = interfaces.getSighash('save');
      const elements = [
        '0x0000000000000000000000000000000000000000000000000000000000000001', // value
      ];

      const spells = [
        utils.concat([
          saveSig, // function selector from address
          '0x80', // flag return value not tuple
          '0x00', // value position from elements array
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF', // returned data position
          VaultMock.address, // address
        ]),
      ];

      expect(await WizadryMock._cast(spells, elements))
        .to.emit(VaultMock, 'Received')
        .withArgs(WizadryMock.address, elements[0]);
    });

    it('should be successfully string concatening using lib with delegatecall', async () => {
      const ABI = ['function strcat(string calldata a, string calldata b)', 'function emitString(string memory str)'];
      const interfaces = new Interface(ABI);
      const strcatSig = interfaces.getSighash('strcat');
      const emitStrSig = interfaces.getSighash('emitString');
      const elements = [
        hexDataSlice(defaultAbiCoder.encode(['string'], ['hello, ']), 32), // value
        hexDataSlice(defaultAbiCoder.encode(['string'], ['world']), 32), // value
      ];

      const spells = [
        utils.concat([
          strcatSig, // function selector from Library address
          '0x00', // flag delegatecall
          '0x80', // value position from elements array. this value is over 32bytes
          '0x81', // value position from elements array. this value is over 32bytes
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0x80', // returned data position on elements array. this value is over 32bytes
          StringLib.address, // address
        ]),
        utils.concat([
          emitStrSig, // function selector from Library address
          '0x00', // flag delegatecall
          '0x80', // value position from elements array. this value is over 32bytes
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF', // returned data position
          EventLib.address, // address
        ]),
      ];

      expect(await WizadryMock._cast(spells, elements))
        .to.emit(EventLib.attach(WizadryMock.address), 'EmittedString')
        .withArgs('hello, world');
    });

    it('should be successfully extension with delegatecall', async () => {
      const ABI = ['function strcat(string calldata a, string calldata b)', 'function emitString(string memory str)'];
      const interfaces = new Interface(ABI);
      const strcatSig = interfaces.getSighash('strcat');
      const emitStrSig = interfaces.getSighash('emitString');
      const elements = [
        hexDataSlice(defaultAbiCoder.encode(['string'], ['hello, ']), 32), // value
        hexDataSlice(defaultAbiCoder.encode(['string'], ['world']), 32), // value
      ];

      const spells = [
        utils.concat([
          strcatSig, // function selector from Library address
          '0x20', // flag delegatecall with extension
          '0x81', // value position from elements array. this value is over 32bytes
          '0x82', // value position from elements array. this value is over 32bytes
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0x80', // returned data position on elements array. this value is over 32bytes
          StringLib.address, // address
        ]),
        utils.concat(['0x8081FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF80']),
        utils.concat([
          emitStrSig, // function selector from Library address
          '0x00', // flag delegatecall
          '0x80', // value position from elements array. this value is over 32bytes
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF', // returned data position
          EventLib.address, // address
        ]),
      ];

      expect(await WizadryMock._cast(spells, elements))
        .to.emit(EventLib.attach(WizadryMock.address), 'EmittedString')
        .withArgs('hello, world');
    });
  });
});
