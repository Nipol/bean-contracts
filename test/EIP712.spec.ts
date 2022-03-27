import { expect } from 'chai';
import hre, { ethers } from 'hardhat';
import { Contract, BigNumber, constants, Signer } from 'ethers';
import { splitSignature, randomBytes } from 'ethers/lib/utils';

describe('EIP712', () => {
  let EIP712Mock: Contract;
  let EIP712MockSalt: Contract;
  let wallet: Signer;
  let Dummy: Signer;
  const salt = Buffer.from(randomBytes(32));
  const saltStr = '0x' + salt.toString('hex');

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, Dummy] = accounts;

    EIP712Mock = await (
      await ethers.getContractFactory('contracts/mocks/EIP712Mock.sol:EIP712Mock', wallet)
    ).deploy(constants.HashZero);

    EIP712MockSalt = await (
      await ethers.getContractFactory('contracts/mocks/EIP712Mock.sol:EIP712Mock', wallet)
    ).deploy(saltStr);
  });

  describe('eth_signTypedData_v4', () => {
    it('should be success with plain type', async () => {
      const walletAddress = await wallet.getAddress();

      const name = await EIP712Mock.name();
      const version = await EIP712Mock.version();
      const chainId = await wallet.getChainId();
      const contractAddress = EIP712Mock.address;
      const value = constants.MaxUint256;
      const nonce = await EIP712Mock.nonces(walletAddress);

      const types = {
        EIP712Domain: [
          { name: 'name', type: 'string' },
          { name: 'version', type: 'string' },
          { name: 'chainId', type: 'uint256' },
          { name: 'verifyingContract', type: 'address' },
        ],
        Verify: [
          { name: 'owner', type: 'address' },
          { name: 'value', type: 'uint256' },
          { name: 'nonce', type: 'uint256' },
        ],
      };

      const primaryType = 'Verify' as const;

      const domain = {
        name: name,
        version: version,
        chainId: chainId,
        verifyingContract: contractAddress,
      };

      const message = {
        owner: walletAddress,
        value: value.toString(),
        nonce: nonce.toString(),
      };

      const typedMessage = {
        domain,
        types,
        message,
        primaryType,
      };

      const sig = await hre.network.provider.send('eth_signTypedData_v4', [walletAddress, typedMessage]);

      const { v, r, s } = splitSignature(sig);

      await EIP712Mock.connect(Dummy)['verify(address,uint256,uint8,bytes32,bytes32)'](walletAddress, value, v, r, s);
      expect(await EIP712Mock.nonces(walletAddress)).equal(BigNumber.from(1));
    });

    it('should be success with array type', async () => {
      const walletAddress = await wallet.getAddress();

      const name = await EIP712Mock.name();
      const version = await EIP712Mock.version();
      const chainId = await wallet.getChainId();
      const contractAddress = EIP712Mock.address;
      const value = constants.MaxUint256;
      const nonce = await EIP712Mock.nonces(walletAddress);

      const types = {
        EIP712Domain: [
          { name: 'name', type: 'string' },
          { name: 'version', type: 'string' },
          { name: 'chainId', type: 'uint256' },
          { name: 'verifyingContract', type: 'address' },
        ],
        Verify: [
          { name: 'owner', type: 'address' },
          { name: 'values', type: 'uint256[]' },
          { name: 'nonce', type: 'uint256' },
        ],
      };

      const primaryType = 'Verify' as const;

      const domain = {
        name: name,
        version: version,
        chainId: chainId,
        verifyingContract: contractAddress,
      };

      const message = {
        owner: walletAddress,
        values: [value.toString(), value.toString()],
        nonce: nonce.toString(),
      };

      const typedMessage = {
        domain,
        types,
        message,
        primaryType,
      };

      const sig = await hre.network.provider.send('eth_signTypedData_v4', [walletAddress, typedMessage]);

      const { v, r, s } = splitSignature(sig);

      await EIP712Mock.connect(Dummy)['verify(address,uint256[],uint8,bytes32,bytes32)'](
        walletAddress,
        [value, value],
        v,
        r,
        s,
      );
      expect(await EIP712Mock.nonces(walletAddress)).equal(BigNumber.from(1));
    });

    it('should be success with complex type', async () => {
      const walletAddress = await wallet.getAddress();

      const name = await EIP712Mock.name();
      const version = await EIP712Mock.version();
      const chainId = await wallet.getChainId();
      const contractAddress = EIP712Mock.address;
      const value = constants.MaxUint256;
      const nonce = await EIP712Mock.nonces(walletAddress);

      const types = {
        EIP712Domain: [
          { name: 'name', type: 'string' },
          { name: 'version', type: 'string' },
          { name: 'chainId', type: 'uint256' },
          { name: 'verifyingContract', type: 'address' },
        ],
        Verify: [
          { name: 'owner', type: 'address' },
          { name: 'value', type: 'Value' },
          { name: 'nonce', type: 'uint256' },
        ],
        Value: [{ name: 'value', type: 'uint256' }],
      };

      const primaryType = 'Verify' as const;

      const domain = {
        name: name,
        version: version,
        chainId: chainId,
        verifyingContract: contractAddress,
      };

      const message = {
        owner: walletAddress,
        value: {
          value: value.toString(),
        },
        nonce: nonce.toString(),
      };

      const typedMessage = {
        domain,
        types,
        message,
        primaryType,
      };

      const sig = await hre.network.provider.send('eth_signTypedData_v4', [walletAddress, typedMessage]);

      const { v, r, s } = splitSignature(sig);

      await EIP712Mock.connect(Dummy)['verify(address,(uint256),uint8,bytes32,bytes32)'](
        walletAddress,
        { value: value },
        v,
        r,
        s,
      );
      expect(await EIP712Mock.nonces(walletAddress)).equal(BigNumber.from(1));
    });

    it('should be success with very complex type', async () => {
      const walletAddress = await wallet.getAddress();

      const name = await EIP712Mock.name();
      const version = await EIP712Mock.version();
      const chainId = await wallet.getChainId();
      const contractAddress = EIP712Mock.address;
      const value = constants.MaxUint256;
      const nonce = await EIP712Mock.nonces(walletAddress);

      const types = {
        EIP712Domain: [
          { name: 'name', type: 'string' },
          { name: 'version', type: 'string' },
          { name: 'chainId', type: 'uint256' },
          { name: 'verifyingContract', type: 'address' },
        ],
        Verify: [
          { name: 'owner', type: 'address' },
          { name: 'value', type: 'Receiver' },
          { name: 'nonce', type: 'uint256' },
        ],
        Receiver: [{ name: 'value', type: 'uint256[]' }],
      };

      const primaryType = 'Verify' as const;

      const domain = {
        name: name,
        version: version,
        chainId: chainId,
        verifyingContract: contractAddress,
      };

      const message = {
        owner: walletAddress,
        value: {
          value: [value.toString(), value.toString()],
        },
        nonce: nonce.toString(),
      };

      const typedMessage = {
        domain,
        types,
        message,
        primaryType,
      };

      const sig = await hre.network.provider.send('eth_signTypedData_v4', [walletAddress, typedMessage]);

      const { v, r, s } = splitSignature(sig);

      await EIP712Mock.connect(Dummy)['verify(address,(uint256[]),uint8,bytes32,bytes32)'](
        walletAddress,
        {
          value: [value, value],
        },
        v,
        r,
        s,
      );
      expect(await EIP712Mock.nonces(walletAddress)).equal(BigNumber.from(1));
    });

    it('should be success with very complex type', async () => {
      const walletAddress = await wallet.getAddress();

      const name = await EIP712Mock.name();
      const version = await EIP712Mock.version();
      const chainId = await wallet.getChainId();
      const contractAddress = EIP712Mock.address;
      const value = constants.MaxUint256;
      const nonce = await EIP712Mock.nonces(walletAddress);

      const types = {
        EIP712Domain: [
          { name: 'name', type: 'string' },
          { name: 'version', type: 'string' },
          { name: 'chainId', type: 'uint256' },
          { name: 'verifyingContract', type: 'address' },
        ],
        Verify: [
          { name: 'owner', type: 'address' },
          { name: 'value', type: 'Receive' },
          { name: 'nonce', type: 'uint256' },
        ],
        Receive: [
          { name: 'receivers', type: 'address[]' },
          { name: 'values', type: 'uint256[]' },
        ],
      };

      const primaryType = 'Verify' as const;

      const domain = {
        name: name,
        version: version,
        chainId: chainId,
        verifyingContract: contractAddress,
      };

      const message = {
        owner: walletAddress,
        value: {
          receivers: [walletAddress, walletAddress],
          values: [value.toString(), value.toString()],
        },
        nonce: nonce.toString(),
      };

      const typedMessage = {
        domain,
        types,
        message,
        primaryType,
      };

      const sig = await hre.network.provider.send('eth_signTypedData_v4', [walletAddress, typedMessage]);
      const { v, r, s } = splitSignature(sig);

      await EIP712Mock.connect(Dummy)['verify(address,(address[],uint256[]),uint8,bytes32,bytes32)'](
        walletAddress,
        {
          receivers: [walletAddress, walletAddress],
          values: [value, value],
        },
        v,
        r,
        s,
      );
      expect(await EIP712Mock.nonces(walletAddress)).equal(BigNumber.from(1));
    });

    it('should be success with Mail Example', async () => {
      const walletAddress = await wallet.getAddress();

      const name = await EIP712Mock.name();
      const version = await EIP712Mock.version();
      const chainId = await wallet.getChainId();
      const contractAddress = EIP712Mock.address;
      const nonce = await EIP712Mock.nonces(walletAddress);

      const types = {
        EIP712Domain: [
          { name: 'name', type: 'string' },
          { name: 'version', type: 'string' },
          { name: 'chainId', type: 'uint256' },
          { name: 'verifyingContract', type: 'address' },
        ],
        Verify: [
          { name: 'owner', type: 'address' },
          { name: 'mail', type: 'Mail' },
          { name: 'nonce', type: 'uint256' },
        ],
        Person: [
          {
            name: 'name',
            type: 'string',
          },
          {
            name: 'wallets',
            type: 'address[]',
          },
        ],
        Mail: [
          {
            name: 'from',
            type: 'Person',
          },
          {
            name: 'to',
            type: 'Person[]',
          },
          {
            name: 'contents',
            type: 'string',
          },
        ],
      };

      const primaryType = 'Verify' as const;

      const domain = {
        name: name,
        version: version,
        chainId: chainId,
        verifyingContract: contractAddress,
      };

      const message = {
        owner: walletAddress,
        mail: {
          contents: 'Hello, Bob!',
          from: {
            name: 'Cow',
            wallets: ['0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826', '0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF'],
          },
          to: [
            {
              name: 'Bob',
              wallets: [
                '0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB',
                '0xB0BdaBea57B0BDABeA57b0bdABEA57b0BDabEa57',
                '0xB0B0b0b0b0b0B000000000000000000000000000',
              ],
            },
          ],
        },
        nonce: nonce.toString(),
      };

      const typedMessage = {
        domain,
        types,
        message,
        primaryType,
      };

      const sig = await hre.network.provider.send('eth_signTypedData_v4', [walletAddress, typedMessage]);
      const { v, r, s } = splitSignature(sig);

      await EIP712Mock.connect(Dummy)[
        'verify(address,((string,address[]),(string,address[])[],string),uint8,bytes32,bytes32)'
      ](
        walletAddress,
        {
          contents: 'Hello, Bob!',
          from: {
            name: 'Cow',
            wallets: ['0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826', '0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF'],
          },
          to: [
            {
              name: 'Bob',
              wallets: [
                '0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB',
                '0xB0BdaBea57B0BDABeA57b0bdABEA57b0BDabEa57',
                '0xB0B0b0b0b0b0B000000000000000000000000000',
              ],
            },
          ],
        },
        v,
        r,
        s,
      );
      expect(await EIP712Mock.nonces(walletAddress)).equal(BigNumber.from(1));
    });

    it.skip('should be success with plain type and salt', async () => {
      const walletAddress = await wallet.getAddress();

      const name = await EIP712MockSalt.name();
      const version = await EIP712MockSalt.version();
      const chainId = await wallet.getChainId();
      const contractAddress = EIP712MockSalt.address;
      const value = constants.MaxUint256;
      const nonce = await EIP712MockSalt.nonces(walletAddress);

      const types = {
        EIP712Domain: [
          { name: 'name', type: 'string' },
          { name: 'version', type: 'string' },
          { name: 'chainId', type: 'uint256' },
          { name: 'verifyingContract', type: 'address' },
          { name: 'salt', type: 'bytes32' },
        ],
        Verify: [
          { name: 'owner', type: 'address' },
          { name: 'value', type: 'uint256' },
          { name: 'nonce', type: 'uint256' },
        ],
      };

      const primaryType = 'Verify' as const;

      const domain = {
        name: name,
        version: version,
        chainId: chainId,
        verifyingContract: contractAddress,
        salt: salt,
      };

      const message = {
        owner: walletAddress,
        value: value.toString(),
        nonce: nonce.toString(),
      };

      const typedMessage = {
        domain,
        types,
        message,
        primaryType,
      };

      const sig = await hre.network.provider.send('eth_signTypedData_v4', [walletAddress, typedMessage]);

      const { v, r, s } = splitSignature(sig);

      await EIP712MockSalt.connect(Dummy)['verify(address,uint256,uint8,bytes32,bytes32)'](
        walletAddress,
        value,
        v,
        r,
        s,
      );
      expect(await EIP712MockSalt.nonces(walletAddress)).equal(BigNumber.from(1));
    });

    it.skip('should be success with array type and salt', async () => {
      const walletAddress = await wallet.getAddress();

      const name = await EIP712MockSalt.name();
      const version = await EIP712MockSalt.version();
      const chainId = await wallet.getChainId();
      const contractAddress = EIP712MockSalt.address;
      const value = constants.MaxUint256;
      const nonce = await EIP712MockSalt.nonces(walletAddress);

      const types = {
        EIP712Domain: [
          { name: 'name', type: 'string' },
          { name: 'version', type: 'string' },
          { name: 'chainId', type: 'uint256' },
          { name: 'verifyingContract', type: 'address' },
          { name: 'salt', type: 'bytes32' },
        ],
        Verify: [
          { name: 'owner', type: 'address' },
          { name: 'values', type: 'uint256[]' },
          { name: 'nonce', type: 'uint256' },
        ],
      };

      const primaryType = 'Verify' as const;

      const domain = {
        name: name,
        version: version,
        chainId: chainId,
        verifyingContract: contractAddress,
        salt: salt,
      };

      const message = {
        owner: walletAddress,
        values: [value.toString(), value.toString()],
        nonce: nonce.toString(),
      };

      const typedMessage = {
        domain,
        types,
        message,
        primaryType,
      };

      const sig = await hre.network.provider.send('eth_signTypedData_v4', [walletAddress, typedMessage]);

      const { v, r, s } = splitSignature(sig);

      await EIP712MockSalt.connect(Dummy)['verify(address,uint256[],uint8,bytes32,bytes32)'](
        walletAddress,
        [value, value],
        v,
        r,
        s,
      );
      expect(await EIP712MockSalt.nonces(walletAddress)).equal(BigNumber.from(1));
    });

    it.skip('should be success with complex type and salt', async () => {
      const walletAddress = await wallet.getAddress();

      const name = await EIP712MockSalt.name();
      const version = await EIP712MockSalt.version();
      const chainId = await wallet.getChainId();
      const contractAddress = EIP712MockSalt.address;
      const value = constants.MaxUint256;
      const nonce = await EIP712MockSalt.nonces(walletAddress);

      const types = {
        EIP712Domain: [
          { name: 'name', type: 'string' },
          { name: 'version', type: 'string' },
          { name: 'chainId', type: 'uint256' },
          { name: 'verifyingContract', type: 'address' },
          { name: 'salt', type: 'bytes32' },
        ],
        Verify: [
          { name: 'owner', type: 'address' },
          { name: 'value', type: 'Value' },
          { name: 'nonce', type: 'uint256' },
        ],
        Value: [{ name: 'value', type: 'uint256' }],
      };

      const primaryType = 'Verify' as const;

      const domain = {
        name: name,
        version: version,
        chainId: chainId,
        verifyingContract: contractAddress,
        salt: salt,
      };

      const message = {
        owner: walletAddress,
        value: {
          value: value.toString(),
        },
        nonce: nonce.toString(),
      };

      const typedMessage = {
        domain,
        types,
        message,
        primaryType,
      };

      const sig = await hre.network.provider.send('eth_signTypedData_v4', [walletAddress, typedMessage]);

      const { v, r, s } = splitSignature(sig);

      await EIP712MockSalt.connect(Dummy)['verify(address,(uint256),uint8,bytes32,bytes32)'](
        walletAddress,
        { value: value },
        v,
        r,
        s,
      );
      expect(await EIP712MockSalt.nonces(walletAddress)).equal(BigNumber.from(1));
    });
  });
});
