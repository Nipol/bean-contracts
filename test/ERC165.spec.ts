import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer } from 'ethers';
import { Interface, FormatTypes } from 'ethers/lib/utils';

describe('ERC165', () => {
  let InterfaceMock: Contract;

  let wallet: Signer;
  let Dummy: Signer;

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, Dummy] = accounts;

    const InterfaceMockDeployer = await ethers.getContractFactory(
      'contracts/mocks/InterfaceMock.sol:InterfaceMock',
      wallet,
    );
    InterfaceMock = await InterfaceMockDeployer.deploy();
    await InterfaceMock.deployed();
  });

  describe('#supportsInterface()', () => {
    it('should be success', async () => {
      const iface = new Interface([
        'function owner() external view returns (address)',
        'function transferOwnership(address newOwner) external',
        'function supportsInterface(bytes4 interfaceID) external view returns (bool)',
      ]);

      const ERC173Selector = BigNumber.from(iface.getSighash('owner')).xor(iface.getSighash('transferOwnership'));

      expect(await InterfaceMock.supportsInterface(ERC173Selector)).to.equal(true);
      // expect(await InterfaceMock.supportsInterface(iface.getSighash('transferOwnership(address)'))).to.equal(true);
    });
  });
});
