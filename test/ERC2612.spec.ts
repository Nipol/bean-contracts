import { expect } from 'chai';
import hre, { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer } from 'ethers';
import {
  keccak256,
  defaultAbiCoder,
  toUtf8Bytes,
  solidityPack,
  splitSignature,
  arrayify,
  joinSignature,
  SigningKey,
  recoverAddress,
} from 'ethers/lib/utils';

enum ERC2612Errors {
  EXPIRED_TIME = 'ExpiredTime',
  INVALID_SIGNATURE = 'InvalidSignature',
}

const EIP712DOMAIN_TYPEHASH = keccak256(
  toUtf8Bytes('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
);

const PERMIT_TYPEHASH = keccak256(
  toUtf8Bytes('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'),
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
  token: Contract,
  approve: {
    owner: string;
    spender: string;
    value: BigNumber;
  },
  nonce: BigNumber,
  deadline: BigNumber,
): Promise<string> {
  const name = await token.name();
  const version = await token.version();
  // const DOMAIN_SEPARATOR = await token.DOMAIN_SEPARATOR();
  const DOMAIN_SEPARATOR = getDomainSeparator(name, version, chainId, token.address);
  return keccak256(
    solidityPack(
      ['bytes1', 'bytes1', 'bytes32', 'bytes32'],
      [
        '0x19',
        '0x01',
        DOMAIN_SEPARATOR,
        keccak256(
          defaultAbiCoder.encode(
            ['bytes32', 'address', 'address', 'uint256', 'uint256', 'uint256'],
            [PERMIT_TYPEHASH, approve.owner, approve.spender, approve.value, nonce, deadline],
          ),
        ),
      ],
    ),
  );
}

describe('ERC20/ERC2612', () => {
  let ERC20Mock: Contract;

  let wallet: Signer;
  let walletTo: Signer;
  let Dummy: Signer;

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, walletTo, Dummy] = accounts;

    const ERC20Deployer = await ethers.getContractFactory('contracts/mocks/TokenMock.sol:TokenMock', wallet);
    ERC20Mock = await ERC20Deployer.deploy('Sample', 'SMP', 18, '1');

    await ERC20Mock.deployed();
  });

  describe('#permit()', () => {
    it('should be success', async () => {
      const walletAddress = await wallet.getAddress();
      const walletToAddress = await walletTo.getAddress();

      const value = constants.MaxUint256;
      const chainId = await wallet.getChainId();
      const deadline = constants.MaxUint256;
      const nonce = await ERC20Mock.nonces(walletAddress);

      const digest = await getApprovalDigest(
        chainId,
        ERC20Mock,
        { owner: walletAddress, spender: walletToAddress, value },
        nonce,
        deadline,
      );

      const hash = arrayify(digest);

      const sig = joinSignature(
        new SigningKey('0x7c299dda7c704f9d474b6ca5d7fee0b490c8decca493b5764541fe5ec6b65114').signDigest(hash),
      );
      const { v, r, s } = splitSignature(sig);

      ERC20Mock = ERC20Mock.connect(walletTo);

      await expect(ERC20Mock.permit(walletAddress, walletToAddress, value, deadline, v, r, s))
        .to.emit(ERC20Mock, 'Approval')
        .withArgs(walletAddress, walletToAddress, value);
      expect(await ERC20Mock.allowance(walletAddress, walletToAddress)).to.be.equal(value);
    });

    it('should be reverted when expired deadline', async () => {
      const walletAddress = await wallet.getAddress();
      const walletToAddress = await walletTo.getAddress();

      const value = constants.MaxUint256;
      const chainId = 31337;
      const deadline = BigNumber.from('1');
      const nonce = await ERC20Mock.nonces(walletAddress);

      const digest = await getApprovalDigest(
        chainId,
        ERC20Mock,
        { owner: walletAddress, spender: walletToAddress, value },
        nonce,
        deadline,
      );

      const hash = arrayify(digest);

      const sig = joinSignature(
        new SigningKey('0x7c299dda7c704f9d474b6ca5d7fee0b490c8decca493b5764541fe5ec6b65114').signDigest(hash),
      );
      const { r, s, v } = splitSignature(sig);

      ERC20Mock = ERC20Mock.connect(walletTo);

      await expect(ERC20Mock.permit(walletAddress, walletToAddress, value, deadline, v, r, s)).to.be.revertedWith(
        ERC2612Errors.EXPIRED_TIME,
      );
    });

    it('should be reverted with invalid signature', async () => {
      const walletAddress = await wallet.getAddress();
      const walletToAddress = await walletTo.getAddress();

      const value = constants.MaxUint256;
      const chainId = 31337;
      const deadline = constants.MaxUint256;
      const nonce = await ERC20Mock.nonces(walletAddress);

      const digest = await getApprovalDigest(
        chainId,
        ERC20Mock,
        { owner: walletAddress, spender: walletToAddress, value },
        nonce,
        deadline,
      );

      const hash = arrayify(digest);

      const sig = joinSignature(
        new SigningKey('0x7c299dda7c704f9d474b6ca5d7fee0b490c8decca493b5764541fe5ec6b65114').signDigest(hash),
      );
      const { r, s, v } = splitSignature(sig);
      const fakeR = '0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';

      ERC20Mock = ERC20Mock.connect(walletTo);

      await expect(ERC20Mock.permit(walletAddress, walletToAddress, value, deadline, v, fakeR, s)).to.be.revertedWith(
        ERC2612Errors.INVALID_SIGNATURE,
      );
    });

    it('should be success with eth_signTypedData_v4', async () => {
      const walletAddress = await wallet.getAddress();
      const walletToAddress = await walletTo.getAddress();

      const name = await ERC20Mock.name();
      const version = '1';
      const chainId = await wallet.getChainId();
      const tokenAddress = ERC20Mock.address;
      const value = constants.MaxUint256;
      const nonce = await ERC20Mock.nonces(walletAddress);
      const deadline = constants.MaxUint256;

      const types = {
        EIP712Domain: [
          { name: 'name', type: 'string' },
          { name: 'version', type: 'string' },
          { name: 'chainId', type: 'uint256' },
          { name: 'verifyingContract', type: 'address' },
        ],
        Permit: [
          { name: 'owner', type: 'address' },
          { name: 'spender', type: 'address' },
          { name: 'value', type: 'uint256' },
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
        owner: walletAddress,
        spender: walletToAddress,
        value: value.toString(),
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

      const { v, r, s } = splitSignature(sig);

      await expect(ERC20Mock.connect(walletTo).permit(walletAddress, walletToAddress, value, deadline, v, r, s))
        .to.emit(ERC20Mock, 'Approval')
        .withArgs(walletAddress, walletToAddress, value);
      expect(await ERC20Mock.connect(walletTo).allowance(walletAddress, walletToAddress)).to.be.equal(value);
    });
  });
});
