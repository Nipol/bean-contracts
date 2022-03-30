import { expect } from 'chai';
import hre, { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer } from 'ethers';
import {
  keccak256,
  defaultAbiCoder,
  toUtf8Bytes,
  solidityPack,
  arrayify,
  joinSignature,
  splitSignature,
  SigningKey,
} from 'ethers/lib/utils';

enum ERC4494Errors {
  EXPIRED_TIME = 'ExpiredTime',
  INVALID_SIGNATURE = 'InvalidSignature',
}

const EIP712DOMAIN_TYPEHASH = keccak256(
  toUtf8Bytes('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
);

const PERMIT_TYPEHASH = keccak256(
  toUtf8Bytes('Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)'),
);

function getDomainSeparator(name: string, version: string, chainId: number, address: string) {
  return keccak256(
    defaultAbiCoder.encode(
      ['bytes32', 'bytes32', 'bytes32', 'uint256', 'address'],
      [EIP712DOMAIN_TYPEHASH, keccak256(toUtf8Bytes(name)), keccak256(toUtf8Bytes(version)), chainId, address],
    ),
  );
}

async function getApprovalDigest(
  chainId: number,
  NFT: Contract,
  approve: {
    spender: string;
    tokenId: string;
  },
  nonce: BigNumber,
  deadline: BigNumber,
): Promise<string> {
  const name = await NFT.name();
  const version = await NFT.version();
  const DOMAIN_SEPARATOR = getDomainSeparator(name, version, chainId, NFT.address);
  return keccak256(
    solidityPack(
      ['bytes1', 'bytes1', 'bytes32', 'bytes32'],
      [
        '0x19',
        '0x01',
        DOMAIN_SEPARATOR,
        keccak256(
          defaultAbiCoder.encode(
            ['bytes32', 'address', 'uint256', 'uint256', 'uint256'],
            [PERMIT_TYPEHASH, approve.spender, approve.tokenId, nonce, deadline],
          ),
        ),
      ],
    ),
  );
}

describe('ERC721/ERC4494', () => {
  let NFTPermit: Contract;

  let wallet: Signer;
  let walletTo: Signer;
  let Dummy: Signer;

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, walletTo, Dummy] = accounts;

    NFTPermit = await (
      await ethers.getContractFactory('contracts/mocks/NFTPermitMock.sol:NFTPermitMock', wallet)
    ).deploy('SAMPLE NFT', 'SAM');

    await NFTPermit.mint(0);
  });

  describe('#permit()', () => {
    it('should be success with eth_signTypedData_v4', async () => {
      expect(await NFTPermit.getApproved('0')).equal(constants.AddressZero);

      const walletAddress = await wallet.getAddress();
      const walletToAddress = await walletTo.getAddress();
      const name = await NFTPermit.name();
      const version = '1';
      const chainId = await wallet.getChainId();
      const tokenAddress = NFTPermit.address;
      const tokenId = '0';
      const nonce = await NFTPermit.nonces(walletAddress);
      const deadline = constants.MaxUint256;

      const types = {
        EIP712Domain: [
          { name: 'name', type: 'string' },
          { name: 'version', type: 'string' },
          { name: 'chainId', type: 'uint256' },
          { name: 'verifyingContract', type: 'address' },
        ],
        Permit: [
          { name: 'spender', type: 'address' },
          { name: 'tokenId', type: 'uint256' },
          { name: 'nonce', type: 'uint256' },
          { name: 'deadline', type: 'uint256' },
        ],
      };

      const primaryType = 'Permit' as const;

      const domain = {
        name: name,
        version: version,
        chainId: chainId,
        verifyingContract: tokenAddress,
      };

      const message = {
        spender: walletToAddress,
        tokenId: tokenId,
        nonce: nonce.toString(),
        deadline: deadline.toString(),
      };

      const typedMessage = {
        domain,
        types,
        message,
        primaryType,
      };

      const sig = await hre.network.provider.send('eth_signTypedData_v4', [walletAddress, typedMessage]);

      await expect(NFTPermit.connect(walletTo).permit(walletToAddress, tokenId, deadline, sig))
        .to.emit(NFTPermit, 'Approval')
        .withArgs(walletAddress, walletToAddress, tokenId);
      expect(await NFTPermit.getApproved('0')).equal(walletToAddress);
    });

    it('should be success with compact signature', async () => {
      expect(await NFTPermit.getApproved('0')).equal(constants.AddressZero);

      const walletAddress = await wallet.getAddress();
      const walletToAddress = await walletTo.getAddress();
      const name = await NFTPermit.name();
      const version = '1';
      const chainId = await wallet.getChainId();
      const tokenAddress = NFTPermit.address;
      const tokenId = '0';
      const nonce = await NFTPermit.nonces(walletAddress);
      const deadline = constants.MaxUint256;

      const types = {
        EIP712Domain: [
          { name: 'name', type: 'string' },
          { name: 'version', type: 'string' },
          { name: 'chainId', type: 'uint256' },
          { name: 'verifyingContract', type: 'address' },
        ],
        Permit: [
          { name: 'spender', type: 'address' },
          { name: 'tokenId', type: 'uint256' },
          { name: 'nonce', type: 'uint256' },
          { name: 'deadline', type: 'uint256' },
        ],
      };

      const primaryType = 'Permit' as const;

      const domain = {
        name: name,
        version: version,
        chainId: chainId,
        verifyingContract: tokenAddress,
      };

      const message = {
        spender: walletToAddress,
        tokenId: tokenId,
        nonce: nonce.toString(),
        deadline: deadline.toString(),
      };

      const typedMessage = {
        domain,
        types,
        message,
        primaryType,
      };

      const sig = await hre.network.provider.send('eth_signTypedData_v4', [walletAddress, typedMessage]);

      const compactSig = splitSignature(sig).compact;

      await expect(NFTPermit.connect(walletTo).permit(walletToAddress, tokenId, deadline, compactSig))
        .to.emit(NFTPermit, 'Approval')
        .withArgs(walletAddress, walletToAddress, tokenId);
      expect(await NFTPermit.getApproved('0')).equal(walletToAddress);
    });

    it('should be revert with Invalid Signature length', async () => {
      expect(await NFTPermit.getApproved('0')).equal(constants.AddressZero);

      const walletAddress = await wallet.getAddress();
      const walletToAddress = await walletTo.getAddress();
      const name = await NFTPermit.name();
      const version = '1';
      const chainId = await wallet.getChainId();
      const tokenAddress = NFTPermit.address;
      const tokenId = '0';
      const nonce = await NFTPermit.nonces(walletAddress);
      const deadline = constants.MaxUint256;

      const types = {
        EIP712Domain: [
          { name: 'name', type: 'string' },
          { name: 'version', type: 'string' },
          { name: 'chainId', type: 'uint256' },
          { name: 'verifyingContract', type: 'address' },
        ],
        Permit: [
          { name: 'spender', type: 'address' },
          { name: 'tokenId', type: 'uint256' },
          { name: 'nonce', type: 'uint256' },
          { name: 'deadline', type: 'uint256' },
        ],
      };

      const primaryType = 'Permit' as const;

      const domain = {
        name: name,
        version: version,
        chainId: chainId,
        verifyingContract: tokenAddress,
      };

      const message = {
        spender: walletToAddress,
        tokenId: tokenId,
        nonce: nonce.toString(),
        deadline: deadline.toString(),
      };

      const typedMessage = {
        domain,
        types,
        message,
        primaryType,
      };

      const sig = await hre.network.provider.send('eth_signTypedData_v4', [walletAddress, typedMessage]);

      await expect(
        NFTPermit.connect(walletTo).permit(walletToAddress, tokenId, deadline, sig.substring(0, 128)),
      ).to.be.revertedWith(ERC4494Errors.INVALID_SIGNATURE);
      expect(await NFTPermit.getApproved('0')).equal(constants.AddressZero);
    });

    it('should be success with make digest', async () => {
      expect(await NFTPermit.getApproved('0')).equal(constants.AddressZero);

      const walletAddress = await wallet.getAddress();
      const walletToAddress = await walletTo.getAddress();

      const tokenId = '0';
      const chainId = await wallet.getChainId();
      const deadline = constants.MaxUint256;
      const nonce = await NFTPermit.nonces(walletAddress);

      const digest = await getApprovalDigest(
        chainId,
        NFTPermit,
        { spender: walletToAddress, tokenId },
        nonce,
        deadline,
      );

      const hash = arrayify(digest);

      const sig = joinSignature(
        new SigningKey('0x7c299dda7c704f9d474b6ca5d7fee0b490c8decca493b5764541fe5ec6b65114').signDigest(hash),
      );

      NFTPermit = NFTPermit.connect(walletTo);

      await expect(NFTPermit.permit(walletToAddress, tokenId, deadline, sig))
        .to.emit(NFTPermit, 'Approval')
        .withArgs(walletAddress, walletToAddress, tokenId);
      expect(await NFTPermit.getApproved('0')).equal(walletToAddress);
    });

    it('should be reverted when expired deadline', async () => {
      expect(await NFTPermit.getApproved('0')).equal(constants.AddressZero);

      const walletAddress = await wallet.getAddress();
      const walletToAddress = await walletTo.getAddress();
      const name = await NFTPermit.name();
      const version = '1';
      const chainId = await wallet.getChainId();
      const tokenAddress = NFTPermit.address;
      const tokenId = '0';
      const nonce = await NFTPermit.nonces(walletAddress);
      const deadline = BigNumber.from('1');

      const types = {
        EIP712Domain: [
          { name: 'name', type: 'string' },
          { name: 'version', type: 'string' },
          { name: 'chainId', type: 'uint256' },
          { name: 'verifyingContract', type: 'address' },
        ],
        Permit: [
          { name: 'spender', type: 'address' },
          { name: 'tokenId', type: 'uint256' },
          { name: 'nonce', type: 'uint256' },
          { name: 'deadline', type: 'uint256' },
        ],
      };

      const primaryType = 'Permit' as const;

      const domain = {
        name: name,
        version: version,
        chainId: chainId,
        verifyingContract: tokenAddress,
      };

      const message = {
        spender: walletToAddress,
        tokenId: tokenId,
        nonce: nonce.toString(),
        deadline: deadline.toString(),
      };

      const typedMessage = {
        domain,
        types,
        message,
        primaryType,
      };

      const sig = await hre.network.provider.send('eth_signTypedData_v4', [walletAddress, typedMessage]);

      await expect(NFTPermit.connect(walletTo).permit(walletToAddress, tokenId, deadline, sig)).to.be.revertedWith(
        ERC4494Errors.EXPIRED_TIME,
      );
      expect(await NFTPermit.getApproved('0')).equal(constants.AddressZero);
    });

    it('should be reverted with invalid signature from another person', async () => {
      expect(await NFTPermit.getApproved('0')).equal(constants.AddressZero);

      const walletAddress = await wallet.getAddress();
      const walletToAddress = await walletTo.getAddress();
      const name = await NFTPermit.name();
      const version = '1';
      const chainId = await wallet.getChainId();
      const tokenAddress = NFTPermit.address;
      const tokenId = '0';
      const nonce = await NFTPermit.nonces(walletAddress);
      const deadline = constants.MaxUint256;

      const types = {
        EIP712Domain: [
          { name: 'name', type: 'string' },
          { name: 'version', type: 'string' },
          { name: 'chainId', type: 'uint256' },
          { name: 'verifyingContract', type: 'address' },
        ],
        Permit: [
          { name: 'spender', type: 'address' },
          { name: 'tokenId', type: 'uint256' },
          { name: 'nonce', type: 'uint256' },
          { name: 'deadline', type: 'uint256' },
        ],
      };

      const primaryType = 'Permit' as const;

      const domain = {
        name: name,
        version: version,
        chainId: chainId,
        verifyingContract: tokenAddress,
      };

      const message = {
        spender: walletToAddress,
        tokenId: tokenId,
        nonce: nonce.toString(),
        deadline: deadline.toString(),
      };

      const typedMessage = {
        domain,
        types,
        message,
        primaryType,
      };

      const sig = await hre.network.provider.send('eth_signTypedData_v4', [walletAddress, typedMessage]);

      const newsig = '0x12345678' + sig.substring(10, 132);

      await expect(NFTPermit.connect(walletTo).permit(walletToAddress, tokenId, deadline, newsig)).to.be.revertedWith(
        ERC4494Errors.INVALID_SIGNATURE,
      );
      expect(await NFTPermit.getApproved('0')).equal(constants.AddressZero);
    });
  });
});
