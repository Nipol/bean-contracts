import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer, utils } from 'ethers';

function buf2hex(buffer: Buffer) {
  // buffer is an ArrayBuffer
  return '0x' + [...new Uint8Array(buffer)].map(x => x.toString(16).padStart(2, '0')).join('');
}

describe('Witchcraft', () => {
  let WitchcraftMock: Contract;

  let wallet: Signer;
  let Dummy: Signer;

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, Dummy] = accounts;

    const WitchcraftMockDeployer = await ethers.getContractFactory(
      'contracts/mocks/WitchcraftMock.sol:WitchcraftMock',
      wallet,
    );
    WitchcraftMock = await WitchcraftMockDeployer.deploy();
  });

  describe('#extreact()', () => {
    it('should be successfully extract value from elements', async () => {
      const elements = [
        '0x1000000000000000000000000000010000000000000000000000000000000001',
        '0x2000000000000000000000000000020000000000000000000000000000000002',
        '0x3000000000000000000000000000030000000000000000000000000000000003',
      ];

      const indices = utils.concat([
        '0xaaaaaaaa', // function selector
        '0x00', // flag
        '0x02', // value position from elements array
        '0xFF',
        '0xFF',
        '0xFF',
        '0xFF',
        '0xFF',
        '0xFF',
        '0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF', // address
      ]);

      expect(await WitchcraftMock.extract(elements, indices)).to.equal(elements[2]);
    });

    it('should be revert with off index of elements', async () => {
      const elements = [
        '0x1000000000000000000000000000010000000000000000000000000000000001',
        '0x2000000000000000000000000000020000000000000000000000000000000002',
        '0x3000000000000000000000000000030000000000000000000000000000000003',
      ];

      const spell = utils.concat([
        '0xaaaaaaaa', // function selector
        '0x00', // flag
        '0x0f', // value position from elements array
        '0xFF',
        '0xFF',
        '0xFF',
        '0xFF',
        '0xFF',
        '0xFF',
        '0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF', // address
      ]);

      await expect(WitchcraftMock.extract(elements, spell)).to.reverted;
    });
  });

  describe('#toSpell()', () => {
    it('should be successfully', async () => {
      const elements = [
        '0x1f000000000000000000000000000100000000000000000000000000000000a1',
        '0x2f000000000000000000000000000200000000000000000000000000000000b2',
        '0x3f000000000000000000000000000300000000000000000000000000000000c3',
      ];

      const selector = '0xaaaaaaaa';

      const spell = utils.concat([
        selector, // function selector
        '0x00', // flag
        '0x00', // value position from elements array [0]
        '0x01', // value position from elements array [1]
        '0xFF', // value position from elements array [2]
        '0xFF', // value position from elements array [3]
        '0xFF', // value position from elements array [4]
        '0xFF', // value position from elements array [5]
        '0xFF', // value position from elements array [6]
        '0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF', // address
      ]);

      expect(await WitchcraftMock.toSpell(elements, selector, spell)).to.equal(
        ['0x', selector.slice(2), elements[0].slice(2), elements[1].slice(2)].join(''),
      );
    });

    it('should be successfully with all dynamic data', async () => {
      const elements = ['0x1f00000000000000000000000000010000000000000000000000000000b23fc3'];

      const selector = '0xaaaaaaaa';

      const spell = utils.concat([
        selector, // function selector
        '0x00', // flag
        '0xFE', // value position from elements array [0]
        '0xFF', // value position from elements array [1]
        '0xFF', // value position from elements array [2]
        '0xFF', // value position from elements array [3]
        '0xFF', // value position from elements array [4]
        '0xFF', // value position from elements array [5]
        '0xFF', // value position from elements array [6]
        '0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF', // address
      ]);

      expect(await WitchcraftMock.toSpell(elements, selector, spell)).to.equal(
        [
          '0x',
          selector.slice(2), // selector
          '0000000000000000000000000000000000000000000000000000000000000020', // 0x00 ~ 0x1F, data position 0x20 (dynamic)
          '0000000000000000000000000000000000000000000000000000000000000001', // 0x20 ~ 0x3F, count of element data
          '0000000000000000000000000000000000000000000000000000000000000020', // 0x40 ~ 0x5F, length of total array
          '0000000000000000000000000000000000000000000000000000000000000020', // 0x60 ~ 0x7F, length of array in data
          elements[0].slice(2), // 0x80 ~ 0x9F, real data
        ].join(''),
      );
    });

    it('should be successfully with all dynamic data call twice', async () => {
      const elements = ['0x1f00000000000000000000000000010000000000000000000000000000b23fc3'];

      const selector = '0xaaaaaaaa';

      const spell = utils.concat([
        selector, // function selector
        '0x00', // flag
        '0xFE', // value position from elements array [0]
        '0xFE', // value position from elements array [1]
        '0xFF', // value position from elements array [2]
        '0xFF', // value position from elements array [3]
        '0xFF', // value position from elements array [4]
        '0xFF', // value position from elements array [5]
        '0xFF', // value position from elements array [6]
        '0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF', // address
      ]);

      expect(await WitchcraftMock.toSpell(elements, selector, spell)).to.equal(
        [
          '0x',
          selector.slice(2), // selector
          '0000000000000000000000000000000000000000000000000000000000000040', // 0x00 ~ 0x1F, 1st data position
          '00000000000000000000000000000000000000000000000000000000000000c0', // 0x20 ~ 0x3F, 2nd data position
          '0000000000000000000000000000000000000000000000000000000000000001', // 0x40 ~ 0x5F, count of element data
          '0000000000000000000000000000000000000000000000000000000000000020', // 0x60 ~ 0x7F, length of total array
          '0000000000000000000000000000000000000000000000000000000000000020', // 0x80 ~ 0x9F, length of array in data
          elements[0].slice(2), // 0xA0 ~ 0xBF, real data
          '0000000000000000000000000000000000000000000000000000000000000001', // 0xC0 ~ 0xDF, count of element data
          '0000000000000000000000000000000000000000000000000000000000000020', // 0xE0 ~ 0xFF, length of total array
          '0000000000000000000000000000000000000000000000000000000000000020', // 0x100 ~ 0x11F, length of array in data
          elements[0].slice(2), // 0x120 ~ 0x13F, real data
        ].join(''),
      );
    });

    it('should be successfully with all dynamic zero data', async () => {
      const elements: string[] = [];

      const selector = '0xaaaaaaaa';

      const spell = utils.concat([
        selector, // function selector
        '0x00', // flag
        '0xFE', // value position from elements array [0]
        '0xFF', // value position from elements array [1]
        '0xFF', // value position from elements array [2]
        '0xFF', // value position from elements array [3]
        '0xFF', // value position from elements array [4]
        '0xFF', // value position from elements array [5]
        '0xFF', // value position from elements array [6]
        '0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF', // address
      ]);

      expect(await WitchcraftMock.toSpell(elements, selector, spell)).to.equal(
        [
          '0x',
          selector.slice(2), // selector
          '0000000000000000000000000000000000000000000000000000000000000020', // 0x00 ~ 0x1F, data position 0x20 (dynamic)
          '0000000000000000000000000000000000000000000000000000000000000000', // 0x20 ~ 0x3F, count of element data
        ].join(''),
      );
    });

    it('should be successfully with specific dynamic data', async () => {
      const elements = ['0x1f00000000000000000000000000010000000000000000000000000000b23fc3'];

      const selector = '0xaaaaaaaa';

      const spell = utils.concat([
        selector, // function selector
        '0x00', // flag
        '0xC0', // value position from elements array [0]
        '0xFF', // value position from elements array [1]
        '0xFF', // value position from elements array [2]
        '0xFF', // value position from elements array [3]
        '0xFF', // value position from elements array [4]
        '0xFF', // value position from elements array [5]
        '0xFF', // value position from elements array [6]
        '0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF', // address
      ]);

      expect(await WitchcraftMock.toSpell(elements, selector, spell)).to.equal(
        [
          '0x',
          selector.slice(2), // selector
          '0000000000000000000000000000000000000000000000000000000000000020', // 0x00 ~ 0x1F, data position 0x20 (dynamic)
          elements[0].slice(2), // 0x20 ~ 0x3F, real data
        ].join(''),
      );
    });
  });
});

// [
//   '0000000000000000000000000000000000000000000000000000000000000020', // 0x00 ~ 0x1F 데이터 포지션
//   '0000000000000000000000000000000000000000000000000000000000000002', // 0x20 ~ 0x3F 요소 2개
//   '0000000000000000000000000000000000000000000000000000000000000040', // 0x40 ~ 0x5F 배열일 때 엘리먼트 총 길이
//   '0000000000000000000000000000000000000000000000000000000000000080', // 0x60 ~ 0x7F 해석할 데이터 포인트
//   '0000000000000000000000000000000000000000000000000000000000000020', // 0x80 ~ 0x9F
//   '1f00000000000000000000000000010000000000000000000000000000b23fc3', // 0xA0 ~ 0xBF
//   '0000000000000000000000000000000000000000000000000000000000000020', // 0xC0 ~ 0xDF
//   '2f00000000000000000000000000010000000000000000000000000000b23fc3', // 0xE0 ~ 0xFF
// ];

// [
//   '0000000000000000000000000000000000000000000000000000000000000020', // 0x00 ~ 0x1F 데이터 포지션
//   '0000000000000000000000000000000000000000000000000000000000000003', // 0x20 ~ 0x3F 요소 3개
//   '0000000000000000000000000000000000000000000000000000000000000060', // 0x40 ~ 0x5F 배열일 때 엘리먼트의 총 길이
//   '00000000000000000000000000000000000000000000000000000000000000a0', // 0x60 ~ 0x7F 해석할 데이터 포인트
//   '00000000000000000000000000000000000000000000000000000000000000e0', // 0x80 ~ 0x9F 224 ?
//   '0000000000000000000000000000000000000000000000000000000000000020', // 0xA0 ~ 0xBF data start
//   '1f00000000000000000000000000010000000000000000000000000000b23fc3', // 0xC0 ~ 0xDF
//   '0000000000000000000000000000000000000000000000000000000000000020', // 0xE0 ~ 0xFF
//   '2f00000000000000000000000000010000000000000000000000000000b23fc3',
//   '0000000000000000000000000000000000000000000000000000000000000020',
//   '3f00000000000000000000000000010000000000000000000000000000b23fc3',
// ];

// [
//   '0000000000000000000000000000000000000000000000000000000000000020', // 0x00 ~ 0x1F 데이터 포지션
//   '0000000000000000000000000000000000000000000000000000000000000004', // 0x20 ~ 0x3F 요소 4개
//   '0000000000000000000000000000000000000000000000000000000000000080', // 0x40 ~ 0x5F 배열일 때 엘리먼트의 총 길이
//   '00000000000000000000000000000000000000000000000000000000000000c0', // 0x60 ~ 0x7F 해석할 데이터 포인트
//   '0000000000000000000000000000000000000000000000000000000000000100', // 0x80 ~ 0x9F 256 ?
//   '0000000000000000000000000000000000000000000000000000000000000140', // 0xA0 ~ 0xBF 320 ?
//   '0000000000000000000000000000000000000000000000000000000000000020', // 0xC0 ~ 0xDF data start
//   '1f00000000000000000000000000010000000000000000000000000000b23fc3', // 0xE0 ~ 0xFF
//   '0000000000000000000000000000000000000000000000000000000000000020',
//   '2f00000000000000000000000000010000000000000000000000000000b23fc3',
//   '0000000000000000000000000000000000000000000000000000000000000020',
//   '3f00000000000000000000000000010000000000000000000000000000b23fc3',
//   '0000000000000000000000000000000000000000000000000000000000000020',
//   '3f00000000000000000000000000010000000000000000000000000000b23fc3',
// ];
