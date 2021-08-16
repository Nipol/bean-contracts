import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer } from 'ethers';
import { Interface, FormatTypes } from 'ethers/lib/utils';

describe.only('ERC165', () => {
  let InterfaceMock: Contract;

  let wallet: Signer;
  let Dummy: Signer;

  const seedPhrase = 'Beacon Test🚏';

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

      console.log(iface.getSighash('supportsInterface(bytes4)'));

      expect(await InterfaceMock.supportsInterface(iface.getSighash('supportsInterface(bytes4)'))).to.equal(true);
      expect(await InterfaceMock.supportsInterface(iface.getSighash('transferOwnership(address)'))).to.equal(true);
    });
  });
});
