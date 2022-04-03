import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, BigNumber, Signer } from 'ethers';
import { Interface } from 'ethers/lib/utils';

describe('WETH', () => {
  let WETH: Contract;
  let wallet: Signer;
  let walletTo: Signer;
  let Dummy: Signer;

  beforeEach(async () => {
    const accounts = await ethers.getSigners();
    [wallet, walletTo, Dummy] = accounts;

    WETH = await (await ethers.getContractFactory('contracts/library/WETH.sol:WETH', wallet)).deploy();
  });

  describe('#receive()', () => {
    it('should be success, deposit eth', async () => {
      const walletAddress = await wallet.getAddress();
      const value = BigNumber.from('5000000000000000000');

      expect(await WETH.balanceOf(walletAddress)).to.be.equal('0');
      expect(await wallet.provider?.getBalance(WETH.address)).to.be.equal('0');

      await expect(
        wallet.sendTransaction({
          to: WETH.address,
          value,
        }),
      )
        .emit(WETH, 'Deposit')
        .withArgs(walletAddress, value);

      expect(await WETH.balanceOf(walletAddress)).to.be.equal(value);
      expect(await wallet.provider?.getBalance(WETH.address)).to.be.equal(value);
    });
  });

  describe('#deposit()', () => {
    it('should be success, deposit eth', async () => {
      const walletAddress = await wallet.getAddress();
      const value = BigNumber.from('5000000000000000000');

      expect(await WETH.balanceOf(walletAddress)).to.be.equal('0');
      expect(await wallet.provider?.getBalance(WETH.address)).to.be.equal('0');

      await expect(WETH.deposit({ value })).emit(WETH, 'Deposit').withArgs(walletAddress, value);

      expect(await WETH.balanceOf(walletAddress)).to.be.equal(value);
      expect(await wallet.provider?.getBalance(WETH.address)).to.be.equal(value);
    });
  });

  describe('#withdraw()', () => {
    let value: BigNumber;

    beforeEach(async () => {
      value = BigNumber.from('5000000000000000000');

      await wallet.sendTransaction({
        to: WETH.address,
        value,
      });
    });

    it('should be success, withdraw eth', async () => {
      const walletAddress = await wallet.getAddress();
      expect(await WETH.balanceOf(walletAddress)).to.be.equal(value);
      expect(await wallet.provider?.getBalance(WETH.address)).to.be.equal(value);

      await expect(WETH.withdraw(value)).emit(WETH, 'Withdrawal').withArgs(walletAddress, value);

      expect(await WETH.balanceOf(walletAddress)).to.be.equal('0');
      expect(await wallet.provider?.getBalance(WETH.address)).to.be.equal('0');
    });
  });

  describe('#supportsInterface', () => {
    it('should be corrected return value from invalid interface', async () => {
      expect(await WETH.supportsInterface('0x00000001')).to.equal(false);
    });

    it('should be success implement ERC20', async () => {
      const iface = new Interface([
        // ERC20
        'function name()',
        'function symbol()',
        'function decimals()',
        'function totalSupply()',
        'function transfer(address to, uint256 value)',
        'function transferFrom(address from,address to,uint256 value)',
        'function approve(address spender, uint256 value)',
        'function balanceOf(address target)',
        'function allowance(address owner, address spender)',
      ]);
      const ERC20Selector = BigNumber.from(iface.getSighash('name'))
        .xor(iface.getSighash('symbol'))
        .xor(iface.getSighash('decimals'))
        .xor(iface.getSighash('totalSupply'))
        .xor(iface.getSighash('transfer'))
        .xor(iface.getSighash('transferFrom'))
        .xor(iface.getSighash('approve'))
        .xor(iface.getSighash('balanceOf'))
        .xor(iface.getSighash('allowance'));
      expect(await WETH.supportsInterface(ERC20Selector.toHexString())).to.equal(true);
    });

    it('should be success implement ERC2612', async () => {
      const iface = new Interface([
        // ERC2612
        'function permit(address owner,address spender,uint256 value,uint256 deadline,uint8 v,bytes32 r,bytes32 s)',
      ]);
      expect(await WETH.supportsInterface(iface.getSighash('permit'))).to.equal(true);
    });

    it('should be success implement ERC165', async () => {
      const iface = new Interface([
        // ERC165
        'function supportsInterface(bytes4 interfaceID) external view returns (bool)',
      ]);
      expect(await WETH.supportsInterface(iface.getSighash('supportsInterface'))).to.equal(true);
    });
  });

  // describe('#transfer()', () => {
  //   it('should be reverted, over Transfer Value', async () => {
  //     const value = initialToken.add('1');
  //     const walletAddress = await wallet.getAddress();
  //     await expect(StandardToken.transfer(walletAddress, value)).to.be.revertedWith(
  //       ERC20Errors.ARITHMETIC_OVERFLOW_OR_UNDERFLOW,
  //     );
  //   });

  //   it('should be reverted, to token contract transfer', async () => {
  //     const value = initialToken.add('1');
  //     await expect(StandardToken.transfer(StandardToken.address, value)).to.be.revertedWith(
  //       ERC20Errors.ARITHMETIC_OVERFLOW_OR_UNDERFLOW,
  //     );
  //   });

  //   it('should be successfully Transfer', async () => {
  //     const value = BigNumber.from('1000000000000000000');
  //     const walletAddress = await wallet.getAddress();
  //     const walletToAddress = await walletTo.getAddress();

  //     await expect(StandardToken.transfer(walletToAddress, value))
  //       .to.emit(StandardToken, 'Transfer')
  //       .withArgs(walletAddress, walletToAddress, value);
  //     expect(await StandardToken.balanceOf(walletToAddress)).to.equal(value);
  //     const balance = initialToken.sub(value);
  //     expect(await StandardToken.balanceOf(walletAddress)).to.equal(balance);
  //   });
  // });

  // describe('#transferFrom()', () => {
  //   it('should be reverted, not Allow with value transfer', async () => {
  //     const value = BigNumber.from('5000000000000000000');
  //     const walletAddress = await wallet.getAddress();
  //     const walletToAddress = await walletTo.getAddress();
  //     const DummyAddress = await Dummy.getAddress();

  //     await expect(StandardToken.approve(walletToAddress, value))
  //       .to.emit(StandardToken, 'Approval')
  //       .withArgs(walletAddress, walletToAddress, value);
  //     expect(await StandardToken.allowance(walletAddress, walletToAddress)).to.be.equal(value);

  //     await StandardToken.connect(walletTo);

  //     const newValue = value.add('1');
  //     await expect(StandardToken.transferFrom(walletAddress, DummyAddress, newValue)).to.be.revertedWith(
  //       ERC20Errors.ARITHMETIC_OVERFLOW_OR_UNDERFLOW,
  //     );
  //   });

  //   it('should be reverted, over transfer value', async () => {
  //     const value = constants.MaxUint256;
  //     const walletAddress = await wallet.getAddress();
  //     const walletToAddress = await walletTo.getAddress();
  //     const DummyAddress = await Dummy.getAddress();

  //     await expect(StandardToken.approve(walletToAddress, value))
  //       .to.emit(StandardToken, 'Approval')
  //       .withArgs(walletAddress, walletToAddress, value);
  //     expect(await StandardToken.allowance(walletAddress, walletToAddress)).to.be.equal(value);

  //     StandardToken = await StandardToken.connect(walletTo);

  //     const newValue = initialToken.add('1');
  //     await expect(StandardToken.transferFrom(walletAddress, DummyAddress, newValue)).to.be.revertedWith(
  //       ERC20Errors.ARITHMETIC_OVERFLOW_OR_UNDERFLOW,
  //     );
  //   });

  //   it('should be reverted, to token contract transfer', async () => {
  //     const value = BigNumber.from('5000000000000000000');
  //     const walletAddress = await wallet.getAddress();
  //     const walletToAddress = await walletTo.getAddress();

  //     await expect(StandardToken.approve(walletToAddress, value))
  //       .to.emit(StandardToken, 'Approval')
  //       .withArgs(walletAddress, walletToAddress, value);
  //     expect(await StandardToken.allowance(walletAddress, walletToAddress)).to.be.equal(value);

  //     await StandardToken.connect(walletTo);

  //     const newValue = value.add('1');
  //     await expect(StandardToken.transferFrom(walletAddress, StandardToken.address, newValue)).to.be.revertedWith(
  //       ERC20Errors.ARITHMETIC_OVERFLOW_OR_UNDERFLOW,
  //     );
  //   });

  //   it('should be success, over transfer value', async () => {
  //     const value = BigNumber.from('1000000000000000000');
  //     const walletAddress = await wallet.getAddress();
  //     const walletToAddress = await walletTo.getAddress();
  //     const DummyAddress = await Dummy.getAddress();

  //     await expect(StandardToken.approve(walletToAddress, value))
  //       .to.emit(StandardToken, 'Approval')
  //       .withArgs(walletAddress, walletToAddress, value);
  //     expect(await StandardToken.allowance(walletAddress, walletToAddress)).to.be.equal(value);

  //     StandardToken = await StandardToken.connect(walletTo);

  //     await expect(StandardToken.transferFrom(walletAddress, DummyAddress, value))
  //       .to.emit(StandardToken, 'Transfer')
  //       .withArgs(walletAddress, DummyAddress, value);
  //     expect(await StandardToken.balanceOf(walletAddress)).to.be.equal(initialToken.sub(value));
  //     expect(await StandardToken.balanceOf(walletToAddress)).to.be.equal('0');
  //     expect(await StandardToken.balanceOf(DummyAddress)).to.be.equal(value);
  //   });
  // });

  // describe('#mint', () => {
  //   it('should be success minting token', async () => {
  //     const walletAddress = await wallet.getAddress();
  //     expect(await StandardToken.mint(initialToken))
  //       .to.emit(StandardToken, 'Transfer')
  //       .withArgs(constants.AddressZero, walletAddress, initialToken);
  //     expect(await StandardToken.balanceOf(walletAddress)).to.equal(initialToken.mul('2'));
  //     expect(await StandardToken.totalSupply()).to.equal(initialToken.mul('2'));
  //   });

  //   it('should be revert minting maximum amount uint256', async () => {
  //     await expect(StandardToken.mint(constants.MaxUint256)).to.revertedWith(
  //       ERC20Errors.ARITHMETIC_OVERFLOW_OR_UNDERFLOW,
  //     );
  //   });
  // });

  // describe('#mintTo', () => {
  //   it('should be success minting token for dummy', async () => {
  //     const DummyAddress = await Dummy.getAddress();
  //     expect(await StandardToken.mintTo(DummyAddress, initialToken))
  //       .to.emit(StandardToken, 'Transfer')
  //       .withArgs(constants.AddressZero, DummyAddress, initialToken);
  //     expect(await StandardToken.balanceOf(DummyAddress)).to.equal(initialToken);
  //     expect(await StandardToken.totalSupply()).to.equal(initialToken.mul('2'));
  //   });

  //   it('should be revert minting token for self', async () => {
  //     const TokenAddress = StandardToken.address;
  //     await expect(StandardToken.mintTo(TokenAddress, initialToken)).to.revertedWith(
  //       ERC20Errors.ARITHMETIC_OVERFLOW_OR_UNDERFLOW,
  //     );
  //   });

  //   it('should be revert minting maximum amount uint256', async () => {
  //     const DummyAddress = await Dummy.getAddress();
  //     await expect(StandardToken.mintTo(DummyAddress, constants.MaxUint256)).to.revertedWith(
  //       ERC20Errors.ARITHMETIC_OVERFLOW_OR_UNDERFLOW,
  //     );
  //   });
  // });

  // describe('#burn', () => {
  //   it('should be success self burn', async () => {
  //     const walletAddress = await wallet.getAddress();
  //     expect(await StandardToken.burn(initialToken))
  //       .to.emit(StandardToken, 'Transfer')
  //       .withArgs(walletAddress, constants.AddressZero, initialToken);
  //     expect(await StandardToken.balanceOf(walletAddress)).to.equal('0');
  //     expect(await StandardToken.totalSupply()).to.equal('0');
  //   });

  //   it('should be revert at balance zero', async () => {
  //     const walletAddress = await wallet.getAddress();
  //     expect(await StandardToken.burn(initialToken))
  //       .to.emit(StandardToken, 'Transfer')
  //       .withArgs(walletAddress, constants.AddressZero, initialToken);
  //     await expect(StandardToken.burn(initialToken)).to.revertedWith(ERC20Errors.ARITHMETIC_OVERFLOW_OR_UNDERFLOW);
  //   });
  // });

  // describe('#burnFrom', () => {
  //   it('should be success burn another account balance', async () => {
  //     const walletAddress = await wallet.getAddress();
  //     const DummyAddress = await Dummy.getAddress();

  //     await StandardToken.transfer(DummyAddress, initialToken);

  //     await StandardToken.connect(Dummy).approve(walletAddress, constants.MaxUint256);

  //     expect(await StandardToken.burnFrom(DummyAddress, initialToken))
  //       .to.emit(StandardToken, 'Transfer')
  //       .withArgs(DummyAddress, constants.AddressZero, initialToken);

  //     expect(await StandardToken.balanceOf(walletAddress)).to.equal('0');
  //     expect(await StandardToken.balanceOf(DummyAddress)).to.equal('0');
  //     expect(await StandardToken.totalSupply()).to.equal('0');
  //   });

  //   it('should be revert at balance zero', async () => {
  //     const walletAddress = await wallet.getAddress();
  //     const DummyAddress = await Dummy.getAddress();

  //     await StandardToken.connect(Dummy).approve(walletAddress, constants.MaxUint256);

  //     await expect(StandardToken.burnFrom(DummyAddress, initialToken)).revertedWith(
  //       ERC20Errors.ARITHMETIC_OVERFLOW_OR_UNDERFLOW,
  //     );
  //   });

  //   it('should be revert at not approved', async () => {
  //     const DummyAddress = await Dummy.getAddress();
  //     await StandardToken.transfer(DummyAddress, initialToken);
  //     await expect(StandardToken.burnFrom(DummyAddress, initialToken)).revertedWith(
  //       ERC20Errors.ARITHMETIC_OVERFLOW_OR_UNDERFLOW,
  //     );
  //   });
  // });

  // describe('#supportsInterface', () => {
  //   it('should be corrected return value from invalid interface', async () => {
  //     expect(await StandardToken.supportsInterface('0x00000001')).to.equal(false);
  //   });

  //   it('should be success implement ERC20', async () => {
  //     const iface = new Interface([
  //       // ERC20
  //       'function name()',
  //       'function symbol()',
  //       'function decimals()',
  //       'function totalSupply()',
  //       'function transfer(address to, uint256 value)',
  //       'function transferFrom(address from,address to,uint256 value)',
  //       'function approve(address spender, uint256 value)',
  //       'function balanceOf(address target)',
  //       'function allowance(address owner, address spender)',
  //     ]);
  //     const ERC20Selector = BigNumber.from(iface.getSighash('name'))
  //       .xor(iface.getSighash('symbol'))
  //       .xor(iface.getSighash('decimals'))
  //       .xor(iface.getSighash('totalSupply'))
  //       .xor(iface.getSighash('transfer'))
  //       .xor(iface.getSighash('transferFrom'))
  //       .xor(iface.getSighash('approve'))
  //       .xor(iface.getSighash('balanceOf'))
  //       .xor(iface.getSighash('allowance'));
  //     expect(await StandardToken.supportsInterface(ERC20Selector.toHexString())).to.equal(true);
  //   });

  //   it('should be success implement IMint', async () => {
  //     const iface = new Interface([
  //       // IMint
  //       'function mint(uint256 value) external returns (bool)',
  //       'function mintTo(address to, uint256 value) external returns (bool)',
  //     ]);
  //     const IMintSelector = BigNumber.from(iface.getSighash('mint')).xor(iface.getSighash('mintTo'));
  //     expect(await StandardToken.supportsInterface(IMintSelector.toHexString())).to.equal(true);
  //   });

  //   it('should be success implement IBurn', async () => {
  //     const iface = new Interface([
  //       // IBurn
  //       'function burn(uint256 value) external returns (bool)',
  //       'function burnFrom(address from, uint256 value) external returns (bool)',
  //     ]);
  //     const IBurnSelector = BigNumber.from(iface.getSighash('burn')).xor(iface.getSighash('burnFrom'));
  //     expect(await StandardToken.supportsInterface(IBurnSelector.toHexString())).to.equal(true);
  //   });

  //   it('should be success implement ERC2612', async () => {
  //     const iface = new Interface([
  //       // ERC2612
  //       'function permit(address owner,address spender,uint256 value,uint256 deadline,uint8 v,bytes32 r,bytes32 s)',
  //     ]);
  //     expect(await StandardToken.supportsInterface(iface.getSighash('permit'))).to.equal(true);
  //   });

  //   it('should be success implement ERC165', async () => {
  //     const iface = new Interface([
  //       // ERC165
  //       'function supportsInterface(bytes4 interfaceID) external view returns (bool)',
  //     ]);
  //     expect(await StandardToken.supportsInterface(iface.getSighash('supportsInterface'))).to.equal(true);
  //   });

  //   it('should be success implement ERC173', async () => {
  //     const iface = new Interface([
  //       // ERC173
  //       'function owner()',
  //       'function transferOwnership(address newOwner)',
  //     ]);
  //     const ERC173Selector = BigNumber.from(iface.getSighash('owner')).xor(iface.getSighash('transferOwnership'));
  //     expect(await StandardToken.supportsInterface(ERC173Selector.toHexString())).to.equal(true);
  //   });

  //   it('should be success implement IMulticall', async () => {
  //     const iface = new Interface([
  //       // Multicall
  //       'function multicall(bytes[] calldata callData)',
  //     ]);
  //     expect(await StandardToken.supportsInterface(iface.getSighash('multicall'))).to.equal(true);
  //   });
  // });
});
