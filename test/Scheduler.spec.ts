import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer } from 'ethers';
import { Interface, keccak256 } from 'ethers/lib/utils';

export async function latestTimestamp(): Promise<number> {
  return (await ethers.provider.getBlock('latest')).timestamp;
}

describe('Scheduler', () => {
  let SchedulerMock: Contract;
  let wallet: Signer;
  let Dummy: Signer;
  const day = BigNumber.from('60').mul('60').mul('24').mul('1');

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, Dummy] = accounts;

    const SchedulerMockDeployer = await ethers.getContractFactory(
      'contracts/mocks/SchedulerMock.sol:SchedulerMock',
      wallet,
    );
    SchedulerMock = await SchedulerMockDeployer.deploy();
  });

  describe('#setDelay()', () => {
    it('should be success setting up delay', async () => {
      expect(await SchedulerMock.set(day))
        .to.emit(SchedulerMock, 'Delayed')
        .withArgs(day);
    });

    it('should be revert with minimum delay', async () => {
      await expect(SchedulerMock.set(day.sub('1'))).revertedWith('Scheduler/Delay-is-not-within-Range');
    });
  });

  describe('#queue()', () => {
    let id;
    beforeEach(async () => {
      await SchedulerMock.set(day);
    });

    it('should be success setted unique id', async () => {
      let now = await latestTimestamp();
      const nextLevel = now + 1;
      await ethers.provider.send('evm_setNextBlockTimestamp', [nextLevel]);
      const next = day.add(nextLevel.toString());
      id = keccak256('0x1234');
      expect(await SchedulerMock['_queue(bytes32)'](id))
        .to.emit(SchedulerMock, 'Approved')
        .withArgs(id, next);
      await expect((await SchedulerMock.endOf(id)).toString()).to.equal(next.toString());
    });

    it('should be revert with already queued uid.', async () => {
      let now = await latestTimestamp();
      const nextLevel = now + 1;
      await ethers.provider.send('evm_setNextBlockTimestamp', [nextLevel]);
      id = keccak256('0x1234');
      expect(await SchedulerMock['_queue(bytes32)'](id))
        .to.emit(SchedulerMock, 'Approved')
        .withArgs(id, day.add(nextLevel));
      await expect(SchedulerMock['_queue(bytes32)'](id)).revertedWith('Scheduler/Already-Scheduled');
    });

    it('should be revert with prev time', async () => {
      let now = await latestTimestamp();
      const nextLevel = now + 1;
      await ethers.provider.send('evm_setNextBlockTimestamp', [nextLevel]);
      id = keccak256('0x1234');
      await expect(SchedulerMock['_queue(bytes32,uint32)'](id, now - 1)).reverted;
    });
  });

  describe('#resolve()', () => {
    let id: string;
    beforeEach(async () => {
      id = keccak256('0x12');
      await SchedulerMock.set(day);
      await SchedulerMock['_queue(bytes32)'](id);
      let now = await latestTimestamp();
      const nextLevel = now + 1;
      await ethers.provider.send('evm_setNextBlockTimestamp', [nextLevel]);
    });

    it('should be revert with unqueued uid', async () => {
      id = keccak256('0x1234');
      await expect(SchedulerMock._resolve(id)).revertedWith('Scheduler/Not-Queued');
    });

    it('should be revert with not reached time', async () => {
      await expect(SchedulerMock._resolve(id)).revertedWith('Scheduler/Not-Reached-Lock');
    });

    it('should be success staled id with over the grace period', async () => {
      let now = await latestTimestamp();
      const overGrace = day
        .mul('8')
        .add(now + 1)
        .toNumber();
      await ethers.provider.send('evm_setNextBlockTimestamp', [overGrace]);
      expect(await SchedulerMock._resolve(id))
        .to.emit(SchedulerMock, 'Staled')
        .withArgs(id);
      await expect(await SchedulerMock.stateOf(id)).to.equal(3);
      await expect(await SchedulerMock.endOf(id)).to.equal(0);
    });

    it('should be success resolved id', async () => {
      let now = await latestTimestamp();
      const overGrace = day.add(now + 1).toNumber();
      await ethers.provider.send('evm_setNextBlockTimestamp', [overGrace]);
      expect(await SchedulerMock._resolve(id))
        .to.emit(SchedulerMock, 'Resolved')
        .withArgs(id);
      await expect(await SchedulerMock.stateOf(id)).to.equal(2);
      await expect(await SchedulerMock.endOf(id)).to.equal(0);
    });

    it('should be revert with already resolved', async () => {
      let now = await latestTimestamp();
      const overGrace = day.add(now + 1).toNumber();
      await ethers.provider.send('evm_setNextBlockTimestamp', [overGrace]);
      expect(await SchedulerMock._resolve(id))
        .to.emit(SchedulerMock, 'Resolved')
        .withArgs(id);
      await expect(await SchedulerMock.stateOf(id)).to.equal(2);
      await expect(await SchedulerMock.endOf(id)).to.equal(0);
      await expect(SchedulerMock._resolve(id)).revertedWith('Scheduler/Not-Queued');
    });
  });
});
