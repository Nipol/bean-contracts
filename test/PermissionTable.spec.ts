import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer } from 'ethers';

describe('PermissionTable', () => {
  let PermissionTable: Contract;

  let wallet: Signer;
  let Dummy: Signer;

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, Dummy] = accounts;

    PermissionTable = await (
      await ethers.getContractFactory('contracts/mocks/PermissionTableMock.sol:PermissionTableMock', wallet)
    ).deploy();
  });

  describe('#grant()', () => {
    it('should be success grant to user', async () => {
      expect(await PermissionTable.isUser('0x0000000000000000000000000000000000000001', '0xbeefbeef')).equal(false);

      await PermissionTable.Grant('0x0000000000000000000000000000000000000001', '0xbeefbeef', '0x000003');

      expect(await PermissionTable.isUser('0x0000000000000000000000000000000000000001', '0xbeefbeef')).equal(true);
    });

    it('should be success grant to group', async () => {
      await ethers.provider.send('hardhat_setCode', ['0x0000000000000000000000000000000000000001', '0x0001']);

      expect(await PermissionTable.isGroup('0x0000000000000000000000000000000000000001', '0xbeefbeef')).equal(false);

      await PermissionTable.Grant('0x0000000000000000000000000000000000000001', '0xbeefbeef', '0x000200');

      expect(await PermissionTable.isGroup('0x0000000000000000000000000000000000000001', '0xbeefbeef')).equal(true);
    });

    it('should be success grant to root', async () => {
      expect(await PermissionTable.isRoot('0x0000000000000000000000000000000000000001', '0xbeefbeef')).equal(false);

      await PermissionTable.Grant('0x0000000000000000000000000000000000000001', '0xbeefbeef', '0x010000');

      expect(await PermissionTable.isRoot('0x0000000000000000000000000000000000000001', '0xbeefbeef')).equal(true);
    });
  });

  describe('#canCall()', () => {
    beforeEach(async () => {
      await ethers.provider.send('hardhat_setCode', ['0x0000000000000000000000000000000000000001', '0x0001']);
      await ethers.provider.send('hardhat_setCode', ['0x0000000000000000000000000000000000000002', '0x0001']);
      await PermissionTable.Grant('0x0000000000000000000000000000000000000001', '0xdeadbeef', '0x010000');
      await PermissionTable.Grant('0x0000000000000000000000000000000000000002', '0xdeadbeef', '0x000200');
      await PermissionTable.Grant('0x0000000000000000000000000000000000000003', '0xdeadbeef', '0x000003');
    });

    it('should be success with permissioned user', async () => {
      expect(
        await PermissionTable['canCall(address,bytes4)']('0x0000000000000000000000000000000000000003', '0xdeadbeef'),
      ).equal(true);
      expect(
        await PermissionTable['canCall(address,bytes4,uint8)'](
          '0x0000000000000000000000000000000000000003',
          '0xdeadbeef',
          '0x02',
        ),
      ).equal(true);
      expect(
        await PermissionTable['canCall(address,bytes4,uint8,uint8,uint8)'](
          '0x0000000000000000000000000000000000000003',
          '0xdeadbeef',
          '0',
          '0',
          '0x02',
        ),
      ).equal(true);
      expect(
        await PermissionTable['canCall(address,bytes4,uint8)'](
          '0x0000000000000000000000000000000000000003',
          '0xdeadbeef',
          '0x04',
        ),
      ).equal(false);
      expect(
        await PermissionTable['canCall(address,bytes4,uint8,uint8,uint8)'](
          '0x0000000000000000000000000000000000000003',
          '0xdeadbeef',
          '0',
          '0',
          '0x04',
        ),
      ).equal(false);
    });

    it('should be success without permissioned user', async () => {
      expect(
        await PermissionTable['canCall(address,bytes4)']('0x0000000000000000000000000000000000000003', '0xC0ffee00'),
      ).equal(false);
      expect(
        await PermissionTable['canCall(address,bytes4,uint8)'](
          '0x0000000000000000000000000000000000000003',
          '0xC0ffee00',
          '0x04',
        ),
      ).equal(false);
      expect(
        await PermissionTable['canCall(address,bytes4,uint8,uint8,uint8)'](
          '0x0000000000000000000000000000000000000003',
          '0xC0ffee00',
          '0',
          '0',
          '0x04',
        ),
      ).equal(false);
    });

    it('should be success with permissioned group', async () => {
      expect(
        await PermissionTable['canCall(address,bytes4)']('0x0000000000000000000000000000000000000002', '0xdeadbeef'),
      ).equal(true);
      expect(
        await PermissionTable['canCall(address,bytes4,uint8)'](
          '0x0000000000000000000000000000000000000002',
          '0xdeadbeef',
          '0x01',
        ),
      ).equal(true);
      expect(
        await PermissionTable['canCall(address,bytes4,uint8,uint8,uint8)'](
          '0x0000000000000000000000000000000000000002',
          '0xdeadbeef',
          '0',
          '0x01',
          '0',
        ),
      ).equal(true);
      expect(
        await PermissionTable['canCall(address,bytes4,uint8)'](
          '0x0000000000000000000000000000000000000002',
          '0xdeadbeef',
          '0x03',
        ),
      ).equal(false);
      expect(
        await PermissionTable['canCall(address,bytes4,uint8,uint8,uint8)'](
          '0x0000000000000000000000000000000000000002',
          '0xdeadbeef',
          '0',
          '0x03',
          '0',
        ),
      ).equal(false);
    });

    it('should be success without permissioned group', async () => {
      expect(
        await PermissionTable['canCall(address,bytes4)']('0x0000000000000000000000000000000000000002', '0xC0ffee00'),
      ).equal(false);
      expect(
        await PermissionTable['canCall(address,bytes4,uint8)'](
          '0x0000000000000000000000000000000000000002',
          '0xC0ffee00',
          '0x03',
        ),
      ).equal(false);
      expect(
        await PermissionTable['canCall(address,bytes4,uint8,uint8,uint8)'](
          '0x0000000000000000000000000000000000000002',
          '0xC0ffee00',
          '0',
          '0x03',
          '0',
        ),
      ).equal(false);
    });

    it('should be success with permissioned root', async () => {
      expect(
        await PermissionTable['canCall(address,bytes4)']('0x0000000000000000000000000000000000000001', '0xdeadbeef'),
      ).equal(true);
      expect(
        await PermissionTable['canCall(address,bytes4,uint8)'](
          '0x0000000000000000000000000000000000000001',
          '0xdeadbeef',
          '0x00',
        ),
      ).equal(true);
      expect(
        await PermissionTable['canCall(address,bytes4,uint8,uint8,uint8)'](
          '0x0000000000000000000000000000000000000001',
          '0xdeadbeef',
          '0x00',
          '0',
          '0',
        ),
      ).equal(true);
      expect(
        await PermissionTable['canCall(address,bytes4,uint8)'](
          '0x0000000000000000000000000000000000000001',
          '0xdeadbeef',
          '0x02',
        ),
      ).equal(false);
      expect(
        await PermissionTable['canCall(address,bytes4,uint8,uint8,uint8)'](
          '0x0000000000000000000000000000000000000001',
          '0xdeadbeef',
          '0x02',
          '0',
          '0',
        ),
      ).equal(false);
    });

    it('should be success without permissioned root', async () => {
      expect(
        await PermissionTable['canCall(address,bytes4)']('0x0000000000000000000000000000000000000001', '0xC0ffee00'),
      ).equal(false);
      expect(
        await PermissionTable['canCall(address,bytes4,uint8)'](
          '0x0000000000000000000000000000000000000001',
          '0xC0ffee00',
          '0x02',
        ),
      ).equal(false);
      expect(
        await PermissionTable['canCall(address,bytes4,uint8,uint8,uint8)'](
          '0x0000000000000000000000000000000000000001',
          '0xC0ffee00',
          '0x02',
          '0',
          '0',
        ),
      ).equal(false);
    });
  });

  describe('#isAuthenticated()', () => {
    beforeEach(async () => {
      await ethers.provider.send('hardhat_setCode', ['0x0000000000000000000000000000000000000001', '0x0001']);
      await ethers.provider.send('hardhat_setCode', ['0x0000000000000000000000000000000000000002', '0x0001']);
      await PermissionTable.Grant('0x0000000000000000000000000000000000000001', '0xdeadbeef', '0x010000');
      await PermissionTable.Grant('0x0000000000000000000000000000000000000002', '0xdeadbeef', '0x000200');
      await PermissionTable.Grant('0x0000000000000000000000000000000000000003', '0xdeadbeef', '0x000003');
    });

    it('should be success with permissioned user', async () => {
      expect(
        await PermissionTable['isAuthenticated(address,bytes4)'](
          '0x0000000000000000000000000000000000000003',
          '0xdeadbeef',
        ),
      ).equal(3);
      expect(
        await PermissionTable['isAuthenticated(address,bytes4,uint8)'](
          '0x0000000000000000000000000000000000000003',
          '0xdeadbeef',
          '0x02',
        ),
      ).equal(3);
      expect(
        await PermissionTable['isAuthenticated(address,bytes4,uint8,uint8,uint8)'](
          '0x0000000000000000000000000000000000000003',
          '0xdeadbeef',
          '0',
          '0',
          '0x02',
        ),
      ).equal(3);
      expect(
        await PermissionTable['isAuthenticated(address,bytes4,uint8)'](
          '0x0000000000000000000000000000000000000003',
          '0xdeadbeef',
          '0x04',
        ),
      ).equal(0);
      expect(
        await PermissionTable['isAuthenticated(address,bytes4,uint8,uint8,uint8)'](
          '0x0000000000000000000000000000000000000003',
          '0xdeadbeef',
          '0',
          '0',
          '0x04',
        ),
      ).equal(0);
    });

    it('should be success without permissioned user', async () => {
      expect(
        await PermissionTable['isAuthenticated(address,bytes4)'](
          '0x0000000000000000000000000000000000000003',
          '0xC0ffee00',
        ),
      ).equal(0);
      expect(
        await PermissionTable['isAuthenticated(address,bytes4,uint8)'](
          '0x0000000000000000000000000000000000000003',
          '0xC0ffee00',
          '0x04',
        ),
      ).equal(0);
      expect(
        await PermissionTable['isAuthenticated(address,bytes4,uint8,uint8,uint8)'](
          '0x0000000000000000000000000000000000000003',
          '0xC0ffee00',
          '0',
          '0',
          '0x04',
        ),
      ).equal(0);
    });

    it('should be success with permissioned group', async () => {
      expect(
        await PermissionTable['isAuthenticated(address,bytes4)'](
          '0x0000000000000000000000000000000000000002',
          '0xdeadbeef',
        ),
      ).equal(2);
      expect(
        await PermissionTable['isAuthenticated(address,bytes4,uint8)'](
          '0x0000000000000000000000000000000000000002',
          '0xdeadbeef',
          '0x01',
        ),
      ).equal(2);
      expect(
        await PermissionTable['isAuthenticated(address,bytes4,uint8,uint8,uint8)'](
          '0x0000000000000000000000000000000000000002',
          '0xdeadbeef',
          '0',
          '0x01',
          '0',
        ),
      ).equal(2);
      expect(
        await PermissionTable['isAuthenticated(address,bytes4,uint8)'](
          '0x0000000000000000000000000000000000000002',
          '0xdeadbeef',
          '0x03',
        ),
      ).equal(0);
      expect(
        await PermissionTable['isAuthenticated(address,bytes4,uint8,uint8,uint8)'](
          '0x0000000000000000000000000000000000000002',
          '0xdeadbeef',
          '0',
          '0x03',
          '0',
        ),
      ).equal(0);
    });

    it('should be success without permissioned group', async () => {
      expect(
        await PermissionTable['isAuthenticated(address,bytes4)'](
          '0x0000000000000000000000000000000000000002',
          '0xC0ffee00',
        ),
      ).equal(0);
      expect(
        await PermissionTable['isAuthenticated(address,bytes4,uint8)'](
          '0x0000000000000000000000000000000000000002',
          '0xC0ffee00',
          '0x03',
        ),
      ).equal(0);
      expect(
        await PermissionTable['isAuthenticated(address,bytes4,uint8,uint8,uint8)'](
          '0x0000000000000000000000000000000000000002',
          '0xC0ffee00',
          '0',
          '0x03',
          '0',
        ),
      ).equal(0);
    });

    it('should be success with permissioned root', async () => {
      expect(
        await PermissionTable['isAuthenticated(address,bytes4)'](
          '0x0000000000000000000000000000000000000001',
          '0xdeadbeef',
        ),
      ).equal(1);
      expect(
        await PermissionTable['isAuthenticated(address,bytes4,uint8)'](
          '0x0000000000000000000000000000000000000001',
          '0xdeadbeef',
          '0x00',
        ),
      ).equal(1);
      expect(
        await PermissionTable['isAuthenticated(address,bytes4,uint8,uint8,uint8)'](
          '0x0000000000000000000000000000000000000001',
          '0xdeadbeef',
          '0x00',
          '0',
          '0',
        ),
      ).equal(1);
      expect(
        await PermissionTable['isAuthenticated(address,bytes4,uint8)'](
          '0x0000000000000000000000000000000000000001',
          '0xdeadbeef',
          '0x02',
        ),
      ).equal(0);
      expect(
        await PermissionTable['isAuthenticated(address,bytes4,uint8,uint8,uint8)'](
          '0x0000000000000000000000000000000000000001',
          '0xdeadbeef',
          '0x02',
          '0',
          '0',
        ),
      ).equal(0);
    });

    it('should be success without permissioned root', async () => {
      expect(
        await PermissionTable['isAuthenticated(address,bytes4)'](
          '0x0000000000000000000000000000000000000001',
          '0xC0ffee00',
        ),
      ).equal(0);
      expect(
        await PermissionTable['isAuthenticated(address,bytes4,uint8)'](
          '0x0000000000000000000000000000000000000001',
          '0xC0ffee00',
          '0x02',
        ),
      ).equal(0);
      expect(
        await PermissionTable['isAuthenticated(address,bytes4,uint8,uint8,uint8)'](
          '0x0000000000000000000000000000000000000001',
          '0xC0ffee00',
          '0x02',
          '0',
          '0',
        ),
      ).equal(0);
    });
  });
});
