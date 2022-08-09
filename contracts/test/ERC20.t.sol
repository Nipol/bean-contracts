/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {TokenMock, IERC20, IERC165, IERC173, IERC2612} from "../mocks/TokenMock.sol";

contract ERC20Test is Test {
    TokenMock token;
    string private name = "Test Token";
    string private symbol = "TT";
    uint8 private decimals = 18;
    string private version = "1";

    function setUp() public {
        token = new TokenMock(name, symbol, decimals, version);
    }

    function testInitialMetadata() public {
        assertEq(token.name(), name);
        assertEq(token.symbol(), symbol);
        assertEq(token.decimals(), decimals);
        assertEq(token.version(), version);
    }

    function testMintAmount() public {
        token.mint(100e18);
        assertEq(token.totalSupply(), 100e18);
        assertEq(token.balanceOf(address(this)), 100e18);
    }

    function testMintAmountToAddr() public {
        token.mintTo(address(10), 100e18);
        assertEq(token.totalSupply(), 100e18);
        assertEq(token.balanceOf(address(10)), 100e18);
    }

    function testBurnTheToken() public {
        token.mint(100e18);
        assertEq(token.balanceOf(address(this)), 100e18);
        token.burn(1e18);
        assertEq(token.balanceOf(address(this)), 99e18);
    }

    function testFailBurnWithNotEnoughAmount() public {
        token.burn(1e18);
    }

    function testTransfer() public {
        token.mint(100e18);
        assertEq(token.totalSupply(), 100e18);
        assertEq(token.balanceOf(address(this)), 100e18);
        assertEq(token.balanceOf(address(10)), 0);
        token.transfer(address(10), 100e18);
        assertEq(token.totalSupply(), 100e18);
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(10)), 100e18);
    }

    function testNoneApprovedTransferFrom() public {
        token.mintTo(address(10), 100e18);
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("Panic(uint256)")), 0x11));
        token.transferFrom(address(10), address(this), 100e18);
    }

    function testApprovedTransferFrom() public {
        token.mintTo(address(10), 100e18);
        vm.prank(address(10));
        token.approve(address(this), 100e18);
        assertEq(token.allowance(address(10), address(this)), 100e18);
        token.transferFrom(address(10), address(this), 100e18);
        assertEq(token.balanceOf(address(this)), 100e18);
        assertEq(token.allowance(address(10), address(this)), 0);
    }

    function testApprovedTransferFromOverBalance() public {
        token.mintTo(address(10), 100e18);
        vm.prank(address(10));
        token.approve(address(this), 100e18);
        assertEq(token.allowance(address(10), address(this)), 100e18);
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("Panic(uint256)")), 0x11));
        token.transferFrom(address(10), address(this), 101e18);
    }

    function testApproveForTokenAddr() public {
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("ERC20__ApproveToSelf()"))));
        token.approve(address(token), 1);
    }

    function testTransferOverBalance() public {
        assertEq(token.totalSupply(), 0);
        assertEq(token.balanceOf(address(this)), 0);
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("Panic(uint256)")), 0x11));
        token.transfer(address(10), 1);
    }

    function testSupportInterface() public {
        assertTrue(token.supportsInterface(type(IERC20).interfaceId));
        assertTrue(token.supportsInterface(type(IERC165).interfaceId));
        assertTrue(token.supportsInterface(type(IERC173).interfaceId));
        assertTrue(token.supportsInterface(type(IERC2612).interfaceId));
        assertTrue(!token.supportsInterface(0xDEADBEEF));
    }
}
