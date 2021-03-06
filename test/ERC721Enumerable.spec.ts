import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, constants, Signer } from 'ethers';
import { parseEther } from 'ethers/lib/utils';

enum ERC721Errors {
  WRONG_RECEIVER = 'ERC721__WrongERC721Receiver',
  NONE_RECEIVER = 'ERC721__NoneERC721Receiver',
  NOT_OWNER_OR_APPROVER = 'ERC721__NotOwnerOrApprover',
  NOT_ALLOWED = 'ERC721__NotAllowed',
  NOT_APPROVED = 'ERC721__NotApproved',
  NOT_EXIST = 'ERC721__NotExist',
  ALREADY_EXIST = 'ERC721__AlreadyExist',
  OUT_OF_INDEX = 'ERC721Enumerable__OutOfIndex',
  OUT_OF_BOUND = '0x32',
}

describe('ERC721Enumerable', () => {
  let ERC721Mock: Contract;

  let wallet: Signer;
  let Dummy: Signer;
  let Dummy2: Signer;

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, Dummy, Dummy2] = accounts;

    const ERC721MockDeployer = await ethers.getContractFactory(
      'contracts/mocks/ERC721EnumerableMock.sol:ERC721EnumerableMock',
      wallet,
    );
    ERC721Mock = await ERC721MockDeployer.deploy('Optimized NFT', 'ONFT');
  });

  describe('#_mint()', () => {
    it('should be success to EOA', async () => {
      const addr = await Dummy.getAddress();
      expect(await ERC721Mock.mintTo(addr))
        .to.emit(ERC721Mock, 'Transfer')
        .withArgs(constants.AddressZero, addr, '0');
    });

    it('should be revert with to zero address', async () => {
      await expect(ERC721Mock.mintTo(constants.AddressZero)).revertedWith(ERC721Errors.NOT_ALLOWED);
    });

    it('should be reverted with already minted token id', async () => {
      const addr = await Dummy.getAddress();
      await ERC721Mock.mintToId(addr, 0);
      await expect(ERC721Mock.mintToId(addr, 0)).revertedWith(ERC721Errors.ALREADY_EXIST);
    });
  });

  describe('#_safemint()', () => {
    it('should be success to EOA', async () => {
      const addr = await Dummy.getAddress();
      expect(await ERC721Mock['safeMint(address)'](addr))
        .to.emit(ERC721Mock, 'Transfer')
        .withArgs(constants.AddressZero, addr, '0');
    });

    it('should be revert with to zero address', async () => {
      await expect(ERC721Mock['safeMint(address)'](constants.AddressZero)).revertedWith(ERC721Errors.NOT_ALLOWED);
    });

    it('should be revert with no implemented receive function', async () => {
      const DummyTemplateDeployer = await ethers.getContractFactory(
        'contracts/mocks/DummyTemplate.sol:DummyTemplate',
        wallet,
      );
      const DummyTemplate = await DummyTemplateDeployer.deploy();
      await expect(ERC721Mock['safeMint(address)'](DummyTemplate.address)).revertedWith(ERC721Errors.NONE_RECEIVER);
    });

    it('should be success with implemented receive function', async () => {
      const ERC721ReceiveMockDeployer = await ethers.getContractFactory(
        'contracts/mocks/ERC721ReceiveMock.sol:ERC721ReceiveMock',
        wallet,
      );
      const ERC721ReceiveMock = await ERC721ReceiveMockDeployer.deploy();
      await expect(ERC721Mock['safeMint(address)'](ERC721ReceiveMock.address))
        .to.emit(ERC721Mock, 'Transfer')
        .withArgs(constants.AddressZero, ERC721ReceiveMock.address, '0');
    });

    it('should be success with wrong implemented receive function', async () => {
      const ERC721ReceiveMockDeployer = await ethers.getContractFactory(
        'contracts/mocks/ERC721ReceiveMock.sol:NoneERC721ReceiveMock',
        wallet,
      );
      const ERC721ReceiveMock = await ERC721ReceiveMockDeployer.deploy();
      await expect(ERC721Mock['safeMint(address)'](ERC721ReceiveMock.address)).reverted;
    });

    it('should be success with wrong implemented receive function', async () => {
      const ERC721ReceiveMockDeployer = await ethers.getContractFactory(
        'contracts/mocks/ERC721ReceiveMock.sol:RevertERC721ReceiveMock',
        wallet,
      );
      const ERC721ReceiveMock = await ERC721ReceiveMockDeployer.deploy();
      await expect(ERC721Mock['safeMint(address)'](ERC721ReceiveMock.address)).revertedWith('Slurp');
    });

    it('should be denial `onERC721Received` recall', async () => {
      const weakNFT = await (
        await ethers.getContractFactory('contracts/mocks/ExploitERC721Mint.sol:ExploitERC721Mint', wallet)
      ).deploy();

      const Exploiter = await (
        await ethers.getContractFactory('contracts/mocks/ExploitMinter.sol:ExploitMinter', wallet)
      ).deploy(weakNFT.address);

      await wallet.sendTransaction({
        to: Exploiter.address,
        value: parseEther('2'),
      });

      await expect(Exploiter.toMinter()).revertedWith('');
    });
  });

  describe('#_burn()', async () => {
    beforeEach(async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();

      await ERC721Mock.mintTo(walletaddr);
      await ERC721Mock.mintTo(addr);
      expect(await ERC721Mock.isApprovedForAll(walletaddr, addr)).to.deep.equal(false);
    });

    it('should be success owned nft', async () => {
      const walletaddr = await wallet.getAddress();

      expect(await ERC721Mock.burn('0'))
        .to.emit(ERC721Mock, 'Transfer')
        .withArgs(walletaddr, constants.AddressZero, '0');
      expect(await ERC721Mock.ownerOf('0')).to.equal(constants.AddressZero);
      expect(await ERC721Mock.totalSupply()).to.equal('1');
    });

    it('should be revert with none existed nft', async () => {
      await expect(ERC721Mock.burn('3')).revertedWith(ERC721Errors.OUT_OF_BOUND);
      expect(await ERC721Mock.ownerOf('3')).equal(constants.AddressZero);
      expect(await ERC721Mock.totalSupply()).to.equal('2');
    });

    it('should be revert with none exist nft', async () => {
      await ERC721Mock.burn('0');
      await expect(ERC721Mock.burn('0')).revertedWith(ERC721Errors.NOT_ALLOWED);
      expect(await ERC721Mock.ownerOf('0')).equal(constants.AddressZero);
      expect(await ERC721Mock.totalSupply()).to.equal('1');
    });
  });

  describe('#totalSupply()', () => {
    it('should be success', async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();

      await ERC721Mock.mintTo(walletaddr);
      await ERC721Mock.mintTo(addr);
      await ERC721Mock.mintTo(addr);
      await ERC721Mock.mintTo(addr);
      await ERC721Mock.mintTo(addr);
      await expect(ERC721Mock.burn('10')).reverted;
      expect(await ERC721Mock.totalSupply()).to.equal('5');
    });

    it('initial totalsupply 0', async () => {
      expect(await ERC721Mock.totalSupply()).to.equal('0');
      const walletaddr = await wallet.getAddress();

      await ERC721Mock.mintTo(walletaddr);
      expect(await ERC721Mock.totalSupply()).to.equal('1');
      expect(await ERC721Mock.burn('0'))
        .to.emit(ERC721Mock, 'Transfer')
        .withArgs(walletaddr, constants.AddressZero, '0');
      expect(await ERC721Mock.totalSupply()).to.equal('0');
    });
  });

  describe('#balanceOf()', () => {
    it('should be returned zero with none ownership', async () => {
      const addr = await Dummy.getAddress();
      expect(await ERC721Mock.balanceOf(addr)).to.equal('0');
    });

    it('shoule be returned value 0 for zero address', async () => {
      expect(await ERC721Mock.balanceOf(constants.AddressZero)).equal('0');
    });

    it('should be returned one with one ownership', async () => {
      const addr = await Dummy.getAddress();
      expect(await ERC721Mock.mintTo(addr))
        .to.emit(ERC721Mock, 'Transfer')
        .withArgs(constants.AddressZero, addr, '0');
      expect(await ERC721Mock.balanceOf(addr)).to.equal('1');
    });

    it('should be success work', async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();
      expect(await ERC721Mock.mintTo(addr))
        .to.emit(ERC721Mock, 'Transfer')
        .withArgs(constants.AddressZero, addr, '0');
      expect(await ERC721Mock.mintTo(walletaddr))
        .to.emit(ERC721Mock, 'Transfer')
        .withArgs(constants.AddressZero, walletaddr, '1');
      expect(await ERC721Mock.balanceOf(walletaddr)).to.equal('1');
      expect(await ERC721Mock.balanceOf(addr)).to.equal('1');
    });
  });

  describe('#ownerOf()', () => {
    beforeEach(async () => {
      const addr = await Dummy.getAddress();
      const walletaddr = await wallet.getAddress();

      await ERC721Mock.mintTo(addr);
      await ERC721Mock.mintTo(walletaddr);
    });

    it('should be success exist owner', async () => {
      const addr = await Dummy.getAddress();
      const walletaddr = await wallet.getAddress();
      expect(await ERC721Mock.ownerOf('0')).to.equal(addr);
      expect(await ERC721Mock.ownerOf('1')).to.equal(walletaddr);
    });

    it('should be reverted with zero non-exist nft', async () => {
      expect(await ERC721Mock.ownerOf('2')).to.equal(constants.AddressZero);
    });
  });

  describe('#getApproved()', () => {
    it('should be success with approved address', async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();
      await ERC721Mock.mintTo(walletaddr);
      expect(await ERC721Mock.getApproved('0')).to.equal(constants.AddressZero);
      expect(await ERC721Mock.approve(addr, '0'))
        .to.emit(ERC721Mock, 'Approval')
        .withArgs(walletaddr, addr, '0');
      expect(await ERC721Mock.getApproved('0')).to.equal(addr);
    });
  });

  describe('#tokenByIndex()', () => {
    it('should be success with total length', async () => {
      const walletaddr = await wallet.getAddress();
      await ERC721Mock.mintTo(walletaddr);
      await ERC721Mock.mintTo(walletaddr);
      await ERC721Mock.mintTo(walletaddr);
      expect(await ERC721Mock.tokenByIndex('2')).to.equal('2');
    });

    it('should be revert with over length', async () => {
      const walletaddr = await wallet.getAddress();
      await ERC721Mock.mintTo(walletaddr);
      await ERC721Mock.mintTo(walletaddr);
      await ERC721Mock.mintTo(walletaddr);
      await expect(ERC721Mock.tokenByIndex('3')).revertedWith(ERC721Errors.NOT_EXIST);
    });
  });

  describe('#tokenOfOwnerByIndex()', () => {
    it('should be success', async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();
      await ERC721Mock.mintTo(walletaddr);
      await ERC721Mock.mintTo(walletaddr);
      await ERC721Mock.mintTo(walletaddr);
      await ERC721Mock.mintTo(addr);
      await ERC721Mock.mintTo(addr);
      await ERC721Mock.mintTo(addr);
      expect(await ERC721Mock.tokenOfOwnerByIndex(walletaddr, '2')).to.equal('2');
      expect(await ERC721Mock.tokenOfOwnerByIndex(addr, '2')).to.equal('5');
    });

    it('should be revert with over index', async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();
      await ERC721Mock.mintTo(walletaddr);
      await ERC721Mock.mintTo(walletaddr);
      await ERC721Mock.mintTo(walletaddr);
      await ERC721Mock.mintTo(addr);
      await ERC721Mock.mintTo(addr);
      await ERC721Mock.mintTo(addr);
      await expect(ERC721Mock.tokenOfOwnerByIndex(walletaddr, '4')).revertedWith(ERC721Errors.OUT_OF_INDEX);
    });

    it('should be revert with end of reach', async () => {
      const walletaddr = await wallet.getAddress();
      await expect(ERC721Mock.tokenOfOwnerByIndex(walletaddr, '0')).revertedWith(ERC721Errors.OUT_OF_INDEX);
    });
  });

  describe('#setApprovalForAll()', () => {
    beforeEach(async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();

      await ERC721Mock.mintTo(walletaddr);
      await ERC721Mock.mintTo(addr);
      expect(await ERC721Mock.isApprovedForAll(walletaddr, addr)).to.deep.equal(false);
    });

    it('should be success', async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();

      expect(await ERC721Mock.setApprovalForAll(addr, true))
        .to.emit(ERC721Mock, 'ApprovalForAll')
        .withArgs(walletaddr, addr, true);
      expect(await ERC721Mock.isApprovedForAll(walletaddr, addr)).to.equal(true);
    });

    it('should be revert with operator are msg.sender', async () => {
      const walletaddr = await wallet.getAddress();
      await expect(ERC721Mock.setApprovalForAll(walletaddr, true)).revertedWith(ERC721Errors.NOT_APPROVED);
      expect(await ERC721Mock.isApprovedForAll(walletaddr, walletaddr)).to.equal(false);
    });
  });

  describe('#approve()', () => {
    beforeEach(async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();

      await ERC721Mock.mintTo(walletaddr);
      await ERC721Mock.mintTo(addr);
    });

    it('should be success with owner call', async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();
      expect(await ERC721Mock.approve(addr, '0'))
        .to.emit(ERC721Mock, 'Approval')
        .withArgs(walletaddr, addr, '0');
    });

    it('should be revert with already owned nft', async () => {
      const addr = await Dummy.getAddress();
      await expect(ERC721Mock.approve(addr, '1')).revertedWith(ERC721Errors.NOT_ALLOWED);
    });

    it('should be revert with not owner of nft', async () => {
      const addr2 = await Dummy2.getAddress();
      await expect(ERC721Mock.approve(addr2, '1')).revertedWith(ERC721Errors.NOT_ALLOWED);
    });

    it('should be revert with not operator of nft', async () => {
      const addr2 = await Dummy2.getAddress();
      await expect(ERC721Mock.connect(wallet).approve(addr2, '1')).revertedWith(ERC721Errors.NOT_ALLOWED);
    });

    it('should be success with operator call', async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();
      expect(await ERC721Mock.setApprovalForAll(addr, true))
        .to.emit(ERC721Mock, 'ApprovalForAll')
        .withArgs(walletaddr, addr, true);
      expect(await ERC721Mock.connect(Dummy).approve(addr, '0'))
        .to.emit(ERC721Mock, 'Approval')
        .withArgs(walletaddr, addr, '0');
    });
  });

  describe('#transferFrom()', () => {
    beforeEach(async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();

      await ERC721Mock.mintTo(walletaddr);
      await ERC721Mock.mintTo(addr);

      expect(await ERC721Mock.balanceOf(walletaddr)).to.equal('1');
      expect(await ERC721Mock.balanceOf(addr)).to.equal('1');
      expect(await ERC721Mock.ownerOf('0')).to.equal(walletaddr);
    });

    it('should be success transfer', async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();
      expect(await ERC721Mock.transferFrom(walletaddr, addr, '0'))
        .to.emit(ERC721Mock, 'Transfer')
        .withArgs(walletaddr, addr, '0');
      expect(await ERC721Mock.balanceOf(walletaddr)).to.equal('0');
      expect(await ERC721Mock.balanceOf(addr)).to.equal('2');
      expect(await ERC721Mock.ownerOf('0')).to.equal(addr);
    });

    it('should be revert with none existed ntt', async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();
      await expect(ERC721Mock.transferFrom(addr, walletaddr, '5')).revertedWith(ERC721Errors.NOT_EXIST);
    });

    it('should be reverted with not owned nft, caller is not owner', async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();
      await expect(ERC721Mock.connect(Dummy2).transferFrom(addr, walletaddr, '0')).revertedWith(
        ERC721Errors.NOT_OWNER_OR_APPROVER,
      );
      expect(await ERC721Mock.balanceOf(walletaddr)).to.equal('1');
      expect(await ERC721Mock.balanceOf(addr)).to.equal('1');
      expect(await ERC721Mock.ownerOf('0')).to.equal(walletaddr);
    });

    it('should be reverted with not owned nft, caller is owner', async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();
      await expect(ERC721Mock.transferFrom(addr, walletaddr, '0')).revertedWith(ERC721Errors.NOT_ALLOWED);
      expect(await ERC721Mock.balanceOf(walletaddr)).to.equal('1');
      expect(await ERC721Mock.balanceOf(addr)).to.equal('1');
      expect(await ERC721Mock.ownerOf('0')).to.equal(walletaddr);
    });

    it('should be reverted to zero address', async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();
      await expect(ERC721Mock.transferFrom(walletaddr, constants.AddressZero, '0')).revertedWith(
        ERC721Errors.NOT_ALLOWED,
      );
      expect(await ERC721Mock.balanceOf(walletaddr)).to.equal('1');
      expect(await ERC721Mock.balanceOf(addr)).to.equal('1');
      expect(await ERC721Mock.ownerOf('0')).to.equal(walletaddr);
    });

    it('should be success call from approved address', async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();
      const addr2 = await Dummy2.getAddress();
      expect(await ERC721Mock.approve(addr2, '0'))
        .to.emit(ERC721Mock, 'Approval')
        .withArgs(walletaddr, addr2, '0');
      expect(await ERC721Mock.connect(Dummy2).transferFrom(walletaddr, addr, '0'))
        .to.emit(ERC721Mock, 'Transfer')
        .withArgs(walletaddr, addr, '0');
      expect(await ERC721Mock.balanceOf(walletaddr)).to.equal('0');
      expect(await ERC721Mock.balanceOf(addr)).to.equal('2');
      expect(await ERC721Mock.ownerOf('0')).to.equal(addr);
    });

    it('should be success call from approved operator', async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();
      const addr2 = await Dummy2.getAddress();
      expect(await ERC721Mock.setApprovalForAll(addr2, true))
        .to.emit(ERC721Mock, 'ApprovalForAll')
        .withArgs(walletaddr, addr2, true);
      expect(await ERC721Mock.connect(Dummy2).transferFrom(walletaddr, addr, '0'))
        .to.emit(ERC721Mock, 'Transfer')
        .withArgs(walletaddr, addr, '0');
      expect(await ERC721Mock.balanceOf(walletaddr)).to.equal('0');
      expect(await ERC721Mock.balanceOf(addr)).to.equal('2');
      expect(await ERC721Mock.ownerOf('0')).to.equal(addr);
    });
  });

  describe('#safeTransferFrom()', () => {
    beforeEach(async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();

      await ERC721Mock.mintTo(walletaddr);
      await ERC721Mock.mintTo(addr);

      expect(await ERC721Mock.balanceOf(walletaddr)).to.equal('1');
      expect(await ERC721Mock.balanceOf(addr)).to.equal('1');
      expect(await ERC721Mock.ownerOf('0')).to.equal(walletaddr);
    });

    it('should be success transfer to EOA', async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();
      expect(await ERC721Mock['safeTransferFrom(address,address,uint256)'](walletaddr, addr, '0'))
        .to.emit(ERC721Mock, 'Transfer')
        .withArgs(walletaddr, addr, '0');
    });

    it('should be reverted with not owned nft, caller is not owner', async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();
      await expect(
        ERC721Mock.connect(Dummy2)['safeTransferFrom(address,address,uint256)'](addr, walletaddr, '0'),
      ).revertedWith(ERC721Errors.NOT_OWNER_OR_APPROVER);
      expect(await ERC721Mock.balanceOf(walletaddr)).to.equal('1');
      expect(await ERC721Mock.balanceOf(addr)).to.equal('1');
      expect(await ERC721Mock.ownerOf('0')).to.equal(walletaddr);
    });

    it('should be revert with none existed ntt', async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();
      await expect(ERC721Mock['safeTransferFrom(address,address,uint256)'](walletaddr, addr, '5')).revertedWith(
        ERC721Errors.NOT_EXIST,
      );
    });

    it('should be revert with not impl receive function', async () => {
      const walletaddr = await wallet.getAddress();

      const DummyTemplate = await (
        await ethers.getContractFactory('contracts/mocks/DummyTemplate.sol:DummyTemplate', wallet)
      ).deploy();

      await expect(
        ERC721Mock['safeTransferFrom(address,address,uint256)'](walletaddr, DummyTemplate.address, '0'),
      ).revertedWith(ERC721Errors.NONE_RECEIVER);
    });

    it('should be success with implemented receive function', async () => {
      const walletaddr = await wallet.getAddress();

      const ERC721ReceiveMock = await (
        await ethers.getContractFactory('contracts/mocks/ERC721ReceiveMock.sol:ERC721ReceiveMock', wallet)
      ).deploy();

      expect(await ERC721Mock['safeTransferFrom(address,address,uint256)'](walletaddr, ERC721ReceiveMock.address, '0'))
        .to.emit(ERC721Mock, 'Transfer')
        .withArgs(walletaddr, ERC721ReceiveMock.address, '0');
    });

    it('should be revert with implemented revert receive function', async () => {
      const walletaddr = await wallet.getAddress();

      const ERC721ReceiveMock = await (
        await ethers.getContractFactory('contracts/mocks/ERC721ReceiveMock.sol:RevertERC721ReceiveMock', wallet)
      ).deploy();

      await expect(
        ERC721Mock['safeTransferFrom(address,address,uint256)'](walletaddr, ERC721ReceiveMock.address, '0'),
      ).revertedWith('Slurp');
    });

    it('should be success call from approved address', async () => {
      const walletaddr = await wallet.getAddress();
      const addr2 = await Dummy2.getAddress();
      const ERC721ReceiveMock = await (
        await ethers.getContractFactory('contracts/mocks/ERC721ReceiveMock.sol:ERC721ReceiveMock', wallet)
      ).deploy();
      expect(await ERC721Mock.approve(addr2, '0'))
        .to.emit(ERC721Mock, 'Approval')
        .withArgs(walletaddr, addr2, '0');
      expect(
        await ERC721Mock.connect(Dummy2)['safeTransferFrom(address,address,uint256)'](
          walletaddr,
          ERC721ReceiveMock.address,
          '0',
        ),
      )
        .to.emit(ERC721Mock, 'Transfer')
        .withArgs(walletaddr, ERC721ReceiveMock.address, '0');
      expect(await ERC721Mock.balanceOf(walletaddr)).to.equal('0');
      expect(await ERC721Mock.balanceOf(ERC721ReceiveMock.address)).to.equal('1');
      expect(await ERC721Mock.ownerOf('0')).to.equal(ERC721ReceiveMock.address);
    });

    it('should be success call from approved operator', async () => {
      const walletaddr = await wallet.getAddress();
      const addr2 = await Dummy2.getAddress();
      const ERC721ReceiveMock = await (
        await ethers.getContractFactory('contracts/mocks/ERC721ReceiveMock.sol:ERC721ReceiveMock', wallet)
      ).deploy();
      expect(await ERC721Mock.setApprovalForAll(addr2, true))
        .to.emit(ERC721Mock, 'ApprovalForAll')
        .withArgs(walletaddr, addr2, true);
      expect(
        await ERC721Mock.connect(Dummy2)['safeTransferFrom(address,address,uint256)'](
          walletaddr,
          ERC721ReceiveMock.address,
          '0',
        ),
      )
        .to.emit(ERC721Mock, 'Transfer')
        .withArgs(walletaddr, ERC721ReceiveMock.address, '0');
      expect(await ERC721Mock.balanceOf(walletaddr)).to.equal('0');
      expect(await ERC721Mock.balanceOf(ERC721ReceiveMock.address)).to.equal('1');
      expect(await ERC721Mock.ownerOf('0')).to.equal(ERC721ReceiveMock.address);
    });

    it('should be success with implemented receive function with calldata', async () => {
      const walletaddr = await wallet.getAddress();

      const ERC721ReceiveMock = await (
        await ethers.getContractFactory('contracts/mocks/ERC721ReceiveMock.sol:ERC721ReceiveMock', wallet)
      ).deploy();

      expect(
        await ERC721Mock['safeTransferFrom(address,address,uint256,bytes)'](
          walletaddr,
          ERC721ReceiveMock.address,
          '0',
          '0x0000000000000000000000000000000000000000000000000000000000000001',
        ),
      )
        .to.emit(ERC721Mock, 'Transfer')
        .withArgs(walletaddr, ERC721ReceiveMock.address, '0');

      expect(await ERC721ReceiveMock.counter()).equal('1');
    });

    it('should be reverted with not owned nft, caller is not owner with calldata', async () => {
      const walletaddr = await wallet.getAddress();
      const addr = await Dummy.getAddress();

      const ERC721ReceiveMock = await (
        await ethers.getContractFactory('contracts/mocks/ERC721ReceiveMock.sol:ERC721ReceiveMock', wallet)
      ).deploy();

      await expect(
        ERC721Mock.connect(Dummy2)['safeTransferFrom(address,address,uint256,bytes)'](
          addr,
          ERC721ReceiveMock.address,
          '0',
          '0x0000000000000000000000000000000000000000000000000000000000000001',
        ),
      ).revertedWith(ERC721Errors.NOT_OWNER_OR_APPROVER);
      expect(await ERC721Mock.balanceOf(walletaddr)).to.equal('1');
      expect(await ERC721Mock.balanceOf(addr)).to.equal('1');
      expect(await ERC721Mock.ownerOf('0')).to.equal(walletaddr);
      expect(await ERC721ReceiveMock.counter()).equal('0');
    });
  });
});
