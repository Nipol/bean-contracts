import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer } from 'ethers';
import { computeCreateAddress } from './utils';
import { Interface } from 'ethers/lib/utils';

enum ReentrantSafeErrors {
  REENTRANT = 'RentrantSafe__Reentrant',
}

describe('ReentrantSafe', () => {
  let CorrectTarget: Contract;
  let IncorrectTarget: Contract;
  let ReentrantCaller: Contract;

  beforeEach(async () => {
    CorrectTarget = await (
      await ethers.getContractFactory('contracts/mocks/ReentrantMock.sol:ReentrantCorrectMock')
    ).deploy('100');

    IncorrectTarget = await (
      await ethers.getContractFactory('contracts/mocks/ReentrantMock.sol:ReentrantCorrectMock')
    ).deploy('100');
  });

  describe('reentrantStart - reentrantEnd', () => {
    beforeEach(async () => {
      ReentrantCaller = await (
        await ethers.getContractFactory('contracts/mocks/ReentrantMock.sol:EncounterCaller')
      ).deploy(CorrectTarget.address);
    });

    it('should be success call for gas meter', async () => {
      await CorrectTarget.increaseFunc();
    });

    it('should be order of each modifier is correct', async () => {
      expect(await CorrectTarget.encounter()).to.equal('100');
      await expect(ReentrantCaller.increase()).revertedWith(ReentrantSafeErrors.REENTRANT);
      expect(await CorrectTarget.encounter()).to.equal('100');
    });
  });

  describe('reentrantEnd - reentrantStart', () => {
    beforeEach(async () => {
      ReentrantCaller = await (
        await ethers.getContractFactory('contracts/mocks/ReentrantMock.sol:EncounterCaller')
      ).deploy(IncorrectTarget.address);
    });

    it('should be order of each modifier is incorrect', async () => {
      expect(await IncorrectTarget.encounter()).to.equal('100');
      await expect(ReentrantCaller.increase()).revertedWith(ReentrantSafeErrors.REENTRANT);
      expect(await IncorrectTarget.encounter()).to.equal('100');
    });
  });
});
