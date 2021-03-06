import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer, utils } from 'ethers';
import {
  defaultAbiCoder,
  Interface,
  formatBytes32String,
  hexDataSlice,
  keccak256,
  arrayify,
  SigningKey,
  joinSignature,
} from 'ethers/lib/utils';

function buf2hex(buffer: Buffer) {
  // buffer is an ArrayBuffer
  return '0x' + [...new Uint8Array(buffer)].map(x => x.toString(16).padStart(2, '0')).join('');
}

describe('Wizadry', () => {
  let WizadryMock: Contract;
  let TokenMock: Contract;
  let VaultMock: Contract;
  let TokenLib: Contract;
  let StringLib: Contract;
  let EventLib: Contract;
  let DeployLib: Contract;
  let MathLib: Contract;
  let EtherLib: Contract;
  let BytesLib: Contract;
  let CryptographyLib: Contract;

  let wallet: Signer;
  let Dummy: Signer;

  const initialToken = BigNumber.from('100000000000000000000');

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, Dummy] = accounts;

    WizadryMock = await (
      await ethers.getContractFactory('contracts/mocks/WizadryMock.sol:WizadryMock', wallet)
    ).deploy();

    TokenMock = await (
      await ethers.getContractFactory('contracts/mocks/TokenMock.sol:TokenMock', wallet)
    ).deploy('SAMPLE', 'SMPL', 18, '1');

    VaultMock = await (await ethers.getContractFactory('contracts/mocks/VaultMock.sol:VaultMock', wallet)).deploy();

    EventLib = await (
      await ethers.getContractFactory('contracts/mocks/EventSpell.sol:EventSpell', wallet)
    ).deploy();

    MathLib = await (
      await ethers.getContractFactory('contracts/mocks/MathSpell.sol:MathSpell', wallet)
    ).deploy();

    StringLib = await (
      await ethers.getContractFactory('contracts/mocks/StringSpell.sol:StringSpell', wallet)
    ).deploy();

    TokenLib = await (
      await ethers.getContractFactory('contracts/mocks/ERC20Spell.sol:ERC20Spell', wallet)
    ).deploy();

    EtherLib = await (
      await ethers.getContractFactory('contracts/mocks/EtherSpell.sol:EtherSpell', wallet)
    ).deploy();

    DeployLib = await (
      await ethers.getContractFactory('contracts/mocks/DeploySpell.sol:DeploySpell', wallet)
    ).deploy();

    BytesLib = await (
      await ethers.getContractFactory('contracts/mocks/BytesSpell.sol:BytesSpell', wallet)
    ).deploy();

    CryptographyLib = await (
      await ethers.getContractFactory('contracts/mocks/CryptographySpell.sol:CryptographySpell', wallet)
    ).deploy();

    await TokenMock.mintTo(WizadryMock.address, initialToken);
  });

  describe('#cast()', () => {
    it('should be successfully transfer token before balance check using call', async () => {
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
          '0x40', // flag 0x01000000 - call, no ext, no tuple
          '0x00', // 00000000 static elements position 0
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
          '0x40', // flag 0x01000000 - call, no ext, no tuple
          '0x01', // 00000000 static elements position 1
          '0x00', // 00000000 static elements position 0
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

    it('should be successfully transfer token before balance check using delegatecall', async () => {
      const ABI = [
        'function balanceOf(address ERC20,address target)',
        'function safeTransfer(address ERC20,address to,uint256 value)',
      ];
      const interfaces = new Interface(ABI);
      const balanceOfsig = interfaces.getSighash('balanceOf');
      const transferSig = interfaces.getSighash('safeTransfer');
      const elements = [
        '0x000000000000000000000000' + TokenMock.address.slice(2), // tokenlib
        '0x000000000000000000000000' + WizadryMock.address.slice(2), // for balanceof
        '0x000000000000000000000000' + (await Dummy.getAddress()).slice(2), // transfer
      ];

      const spells = [
        utils.concat([
          balanceOfsig, // function selector from address
          '0x00', // flag 0x00000000 - delegatecall, no ext, no tuple
          '0x00', // 00000000 static elements position 0
          '0x01', // 00000000 static elements position 1
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0x01', // returned data position
          TokenLib.address, // address
        ]),
        utils.concat([
          transferSig, // function selector from address
          '0x00', // flag 0x00000000 - delegatecall, no ext, no tuple
          '0x00', // 00000000 static elements position 0
          '0x02', // 00000010 static elements position 2
          '0x01', // 00000001 static elements position 1
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

    it('should be successfully transfer with call value to Vault', async () => {
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
          '0x80', // flag 0x10000000 - call with value, no ext, no tuple
          '0x00', // 00000000 static elements position 0
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

    it('should be successfully bytes manipulate with tuple', async () => {
      const hash = arrayify('0x00000000000000000000000000000000000000000000000000000000000001FA');

      // for 0x22310Bf73bC88ae2D2c9a29Bd87bC38FBAc9e6b0
      const sig = joinSignature(
        new SigningKey('0x7c299dda7c704f9d474b6ca5d7fee0b490c8decca493b5764541fe5ec6b65114').signDigest(hash),
      );

      const ABI = [
        'function splitSignature(bytes memory sig) external pure returns (uint8 v, bytes32 r, bytes32 s)',
        'function mergeSignature(uint8 v, bytes32 r, bytes32 s) external pure returns (bytes memory signature)',
        'function ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) external pure returns (address addr)',
      ];
      const interfaces = new Interface(ABI);
      const splitSig = interfaces.getSighash('splitSignature');
      const mergeSig = interfaces.getSighash('mergeSignature');
      const ecrecoverSig = interfaces.getSighash('ecrecover');
      const elements = [sig, hash];

      const spells = [
        utils.concat([
          splitSig, // function selector from Library address
          '0x10', // flag 0x00010000 - delegatecall, no ext, tuple
          '0x80', // 10000000 encode elements position 0
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0x00', // 00000000 returned data position 0
          BytesLib.address, // address
        ]),
        utils.concat([
          mergeSig, // function selector from Library address
          '0x00', // flag 0x00000000 - delegatecall, no ext, no tuple
          '0x40', // 010000000 pack elements position 0
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0x40', // 01000000 pack elements returned data position 0
          BytesLib.address, // address
        ]),
        utils.concat([
          splitSig, // function selector from Library address
          '0x10', // flag 0x00010000 - delegatecall, no ext, tuple
          '0x80', // 10000000 value position from elements array. this value is over 32bytes
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0x00', // 00000000 returned data position 0
          BytesLib.address, // address
        ]),
        utils.concat([
          mergeSig, // function selector from Library address
          '0x00', // flag 0x00000000 - delegatecall, no ext, no tuple
          '0x40', // 010000000 pack elements position 0
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0x40', // 01000000 pack elements returned data position 0
          BytesLib.address, // address
        ]),
        utils.concat([
          splitSig, // function selector from Library address
          '0x10', // flag 0x00010000 - delegatecall, no ext, tuple
          '0x80', // 10000000 value position from elements array. this value is over 32bytes
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0x00', // 00000000 returned data position 0
          BytesLib.address, // address
        ]),
        utils.concat([
          ecrecoverSig, // function selector from Library address
          '0x00', // flag 0x00000000 - delegatecall, no ext, no tuple
          '0x01', // 00000001 value position from elements array. this value is over 32bytes
          '0x40', // 01000000 value position from elements array. this value is over 32bytes
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0x00', // 00000000 returned data position 0
          CryptographyLib.address,
        ]),
      ];

      // recovered address and digest
      expect(await WizadryMock.callStatic._cast(spells, elements)).to.deep.equal([
        '0x00000000000000000000000022310Bf73bC88ae2D2c9a29Bd87bC38FBAc9e6b0'.toLocaleLowerCase(),
        '0x00000000000000000000000000000000000000000000000000000000000001FA'.toLocaleLowerCase(),
      ]);
    });

    it('should be drop the tuple', async () => {
      const hash = arrayify('0x00000000000000000000000000000000000000000000000000000000000001FA');

      // for 0x22310Bf73bC88ae2D2c9a29Bd87bC38FBAc9e6b0
      const sig = joinSignature(
        new SigningKey('0x7c299dda7c704f9d474b6ca5d7fee0b490c8decca493b5764541fe5ec6b65114').signDigest(hash),
      );

      const ABI = [
        'function splitSignature(bytes memory sig) external pure returns (uint8 v, bytes32 r, bytes32 s)',
        'function mergeSignature(uint8 v, bytes32 r, bytes32 s) external pure returns (bytes memory signature)',
        'function ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) external pure returns (address addr)',
      ];
      const interfaces = new Interface(ABI);
      const splitSig = interfaces.getSighash('splitSignature');
      const mergeSig = interfaces.getSighash('mergeSignature');
      const ecrecoverSig = interfaces.getSighash('ecrecover');
      const elements = [sig, hash];
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
          '0x00', // flag 0x00000000 - delegatecall, no ext, no tuple
          '0xC0', // 11000000 dynamic elements position 0
          '0xC1', // 11000001 dynamic elements position 1
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xC0', // 11000000 dynamic returned data position 0
          StringLib.address, // address
        ]),
        utils.concat([
          emitStrSig, // function selector from Library address
          '0x00', // flag 0x00000000 - delegatecall, no ext, no tuple
          '0xC0', // 11000000 dynamic elements position 0
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

    it('should be successfully string concatening using lib with staticcall', async () => {
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
          '0xC0', // flag staticcall
          '0xC0', // value position from elements array. this value is over 32bytes
          '0xC1', // value position from elements array. this value is over 32bytes
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xC0', // returned data position on elements array. this value is over 32bytes
          StringLib.address, // address
        ]),
        utils.concat([
          emitStrSig, // function selector from Library address
          '0x00', // flag delegatecall
          '0xC0', // value position from elements array. this value is over 32bytes
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
          '0xC1', // value position from elements array. this value is over 32bytes
          '0xC2', // value position from elements array. this value is over 32bytes
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xC0', // returned data position on elements array. this value is over 32bytes
          StringLib.address, // address
        ]),
        utils.concat(['0xC0C1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC0']),
        utils.concat([
          emitStrSig, // function selector from Library address
          '0x00', // flag delegatecall
          '0xC0', // value position from elements array. this value is over 32bytes
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

    it('should be successfully deploy contract with delegatecall', async () => {
      const ABI = [
        'function cast(uint256 value, bytes memory byteCode) external returns (address deployed)',
        'function emitAddress(address addr)',
      ];
      const interfaces = new Interface(ABI);
      const castSig = interfaces.getSighash('cast');
      const emitSig = interfaces.getSighash('emitAddress');

      const contractDeployer = await ethers.getContractFactory(
        'contracts/mocks/DummyTemplate.sol:DummyTemplate',
        wallet,
      );

      const elements = [constants.HashZero, contractDeployer.bytecode];

      const spells = [
        utils.concat([
          castSig, // function selector from Library address
          '0x00', // flag delegatecall with extension
          '0x00', // value position from elements array. this value is over 32bytes
          '0x81', // value position from elements array. this value is over 32bytes
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0x00', // returned data position on elements array. this value is over 32bytes
          DeployLib.address, // address
        ]),
        utils.concat([
          emitSig, // function selector from Library address
          '0x00', // flag delegatecall
          '0x00', // value position from elements array. this value is over 32bytes
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF', // returned data position
          EventLib.address, // address
        ]),
      ];

      const txCount = await ethers.provider.getTransactionCount(WizadryMock.address);
      const deployableAddr = utils.getContractAddress({ from: WizadryMock.address, nonce: txCount });

      expect(await WizadryMock._cast(spells, elements))
        .to.emit(EventLib.attach(WizadryMock.address), 'EmittedAddress')
        .withArgs(deployableAddr);
    });

    it('should be revert with deploy contract on same nonce', async () => {
      const ABI = [
        'function cast(uint256 value, bytes memory byteCode) external returns (address deployed)',
        'function emitAddress(address addr)',
      ];
      const interfaces = new Interface(ABI);
      const castSig = interfaces.getSighash('cast');
      const emitSig = interfaces.getSighash('emitAddress');

      const contractDeployer = await ethers.getContractFactory(
        'contracts/mocks/DummyTemplate.sol:DummyTemplate',
        wallet,
      );

      const elements = [constants.HashZero, contractDeployer.bytecode];

      const spells = [
        utils.concat([
          castSig, // function selector from Library address
          '0x00', // flag delegatecall with extension
          '0x00', // value position from elements array. this value is over 32bytes
          '0x41', // value position from elements array. this value is over 32bytes
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0x00', // returned data position on elements array. this value is over 32bytes
          DeployLib.address, // address
        ]),
        utils.concat([
          castSig, // function selector from Library address
          '0x00', // flag delegatecall with extension
          '0x00', // value position from elements array. this value is over 32bytes
          '0x41', // value position from elements array. this value is over 32bytes
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0x00', // returned data position on elements array. this value is over 32bytes
          DeployLib.address, // address
        ]),
      ];

      await expect(WizadryMock._cast(spells, elements)).to.reverted;
    });

    it('should be successfully deploy contract using create2 with delegatecall', async () => {
      const ABI = [
        'function cast(uint256 value, bytes memory byteCode, bytes32 salt) external returns (address deployed)',
        'function emitAddress(address addr)',
        'function add(uint256 a, uint256 b)',
      ];
      const interfaces = new Interface(ABI);
      const castSig = interfaces.getSighash('cast');
      const emitSig = interfaces.getSighash('emitAddress');
      const addSig = interfaces.getSighash('add');

      const contractDeployer = await ethers.getContractFactory(
        'contracts/mocks/DummyTemplate.sol:DummyTemplate',
        wallet,
      );

      const elements = [
        constants.HashZero, // value
        contractDeployer.bytecode, // deploy
        '0x0000000000000000000000000000000000000000000000000000000000000000', // nonce
        '0x0000000000000000000000000000000000000000000000000000000000000001', // nonce increment
      ];

      const spells = [
        utils.concat([
          castSig, // function selector from Library address
          '0x00', // flag delegatecall with extension
          '0x00', // value position from elements array. this value is over 32bytes
          '0x81', // value position from elements array. this value is over 32bytes
          '0x02',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF', // returned data position on elements array. this value is over 32bytes
          DeployLib.address, // address
        ]),
        utils.concat([
          addSig,
          '0x00', // flag delegatecall with extension
          '0x02', // value position from elements array. this value is over 32bytes
          '0x03', // value position from elements array. this value is over 32bytes
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0x02', // returned data position on elements array. this value is over 32bytes
          MathLib.address, // address
        ]),
        utils.concat([
          castSig, // function selector from Library address
          '0x00', // flag delegatecall with extension
          '0x00', // value position from elements array. this value is over 32bytes
          '0x81', // value position from elements array. this value is over 32bytes
          '0x02',
          '0xFF',
          '0xFF',
          '0xFF',
          '0x00', // returned data position on elements array. this value is over 32bytes
          DeployLib.address, // address
        ]),
        utils.concat([
          emitSig, // function selector from Library address
          '0x00', // flag delegatecall
          '0x00', // value position from elements array. this value is over 32bytes
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF', // returned data position
          EventLib.address, // address
        ]),
      ];

      const deployableAddr = utils.getCreate2Address(WizadryMock.address, elements[3], keccak256(elements[1]));

      expect(await WizadryMock._cast(spells, elements))
        .to.emit(EventLib.attach(WizadryMock.address), 'EmittedAddress')
        .withArgs(deployableAddr);
    });

    it('should be revert deploy contract using create2 with delegatecall', async () => {
      const ABI = [
        'function cast(uint256 value, bytes memory byteCode, bytes32 salt) external returns (address deployed)',
        'function emitAddress(address addr)',
        'function add(uint256 a, uint256 b)',
      ];
      const interfaces = new Interface(ABI);
      const castSig = interfaces.getSighash('cast');
      const emitSig = interfaces.getSighash('emitAddress');
      const addSig = interfaces.getSighash('add');

      const contractDeployer = await ethers.getContractFactory(
        'contracts/mocks/DummyTemplate.sol:DummyTemplate',
        wallet,
      );

      const elements = [
        constants.HashZero, // value
        contractDeployer.bytecode, // deploy
        '0x0000000000000000000000000000000000000000000000000000000000000000', // nonce
      ];

      const spells = [
        utils.concat([
          castSig, // function selector from Library address
          '0x00', // flag delegatecall with extension
          '0x00', // value position from elements array. this value is over 32bytes
          '0x81', // value position from elements array. this value is over 32bytes
          '0x02',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF', // returned data position on elements array. this value is over 32bytes
          DeployLib.address, // address
        ]),
        utils.concat([
          castSig, // function selector from Library address
          '0x00', // flag delegatecall with extension
          '0x00', // value position from elements array. this value is over 32bytes
          '0x81', // value position from elements array. this value is over 32bytes
          '0x02',
          '0xFF',
          '0xFF',
          '0xFF',
          '0x00', // returned data position on elements array. this value is over 32bytes
          DeployLib.address, // address
        ]),
      ];

      await expect(WizadryMock._cast(spells, elements)).to.reverted;
    });

    it('should be revert when transfer ether failed', async () => {
      const ABI = [
        'function cast(uint256 value, bytes memory byteCode, bytes32 salt) external returns (address deployed)',
        'function transfer(address payable to, uint256 amount) external',
        'function emitAddress(address addr)',
        'function add(uint256 a, uint256 b)',
      ];
      const interfaces = new Interface(ABI);
      const castSig = interfaces.getSighash('cast');
      const transferSig = interfaces.getSighash('transfer');

      const contractDeployer = await ethers.getContractFactory(
        'contracts/mocks/DummyTemplate.sol:DummyTemplate',
        wallet,
      );

      const elements = [
        constants.HashZero, // value
        contractDeployer.bytecode, // deploy
        '0x0000000000000000000000000000000000000000000000000000000000000000', // nonce
        '0x0000000000000000000000000000100000000000000000000000000000000000',
      ];

      const spells = [
        utils.concat([
          castSig, // function selector from Library address
          '0x00', // flag delegatecall with extension
          '0x00', // value position from elements array. this value is over 32bytes
          '0x41', // value position from elements array. this value is over 32bytes
          '0x02',
          '0xFF',
          '0xFF',
          '0xFF',
          '0x00', // returned data position on elements array. this value is over 32bytes
          DeployLib.address, // address
        ]),
        utils.concat([
          transferSig, // function selector from Library address
          '0x00', // flag delegatecall with extension
          '0x00', // value position from elements array. this value is over 32bytes
          '0x03', // value position from elements array. this value is over 32bytes
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0x00', // returned data position on elements array. this value is over 32bytes
          EtherLib.address, // address
        ]),
      ];
      const deployableAddr = utils.getCreate2Address(WizadryMock.address, elements[2], keccak256(elements[1]));
      await expect(WizadryMock._cast(spells, elements)).to.reverted;
      expect(await ethers.provider.getCode(deployableAddr)).to.equal('0x');
    });

    it('should be success when send ether failed reason not enough balance', async () => {
      const ABI = [
        'function cast(uint256 value, bytes memory byteCode, bytes32 salt) external returns (address deployed)',
        'function send(address payable to, uint256 amount) external returns (bool suc) ',
        'function emitBytes32(bytes32 data) external',
        'function add(uint256 a, uint256 b)',
      ];
      const interfaces = new Interface(ABI);
      const castSig = interfaces.getSighash('cast');
      const sendSig = interfaces.getSighash('send');
      const emitBytes32Sig = interfaces.getSighash('emitBytes32');

      const contractDeployer = await ethers.getContractFactory(
        'contracts/mocks/DummyTemplate.sol:DummyTemplate',
        wallet,
      );

      const elements = [
        constants.HashZero, // value
        contractDeployer.bytecode, // deploy
        '0x0000000000000000000000000000000000000000000000000000000000000000', // nonce
        '0x0000000000000000000000000000100000000000000000000000000000000000',
      ];

      const spells = [
        utils.concat([
          castSig, // function selector from Library address
          '0x00', // flag delegatecall with extension
          '0x00', // value position from elements array. this value is over 32bytes
          '0x81', // value position from elements array. this value is over 32bytes
          '0x02',
          '0xFF',
          '0xFF',
          '0xFF',
          '0x00', // returned data position on elements array. this value is over 32bytes
          DeployLib.address, // address
        ]),
        utils.concat([
          sendSig, // function selector from Library address
          '0x00', // flag delegatecall with extension
          '0x00', // value position from elements array. this value is over 32bytes
          '0x03', // value position from elements array. this value is over 32bytes
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0x00', // returned data position on elements array. this value is over 32bytes
          EtherLib.address, // address
        ]),
        utils.concat([
          emitBytes32Sig, // function selector from Library address
          '0x00', // flag delegatecall with extension
          '0x00', // value position from elements array. this value is over 32bytes
          '0xFF', // value position from elements array. this value is over 32bytes
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF',
          '0xFF', // returned data position on elements array. this value is over 32bytes
          EventLib.address, // address
        ]),
      ];

      expect(await WizadryMock._cast(spells, elements))
        .to.emit(EventLib.attach(WizadryMock.address), 'EmittedBytes32')
        .withArgs(elements[0]);
    });
  });
});
