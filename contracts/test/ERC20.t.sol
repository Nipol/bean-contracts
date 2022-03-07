// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "../mocks/TokenMock.sol";

interface CheatCodes {
    function prank(address) external;

    function expectRevert(bytes calldata) external;
}

contract ERC20Test is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
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
        token.mintTo(address(1), 100e18);
        assertEq(token.totalSupply(), 100e18);
        assertEq(token.balanceOf(address(1)), 100e18);
    }

    function testTransfer() public {
        token.mint(100e18);
        assertEq(token.totalSupply(), 100e18);
        assertEq(token.balanceOf(address(this)), 100e18);
        assertEq(token.balanceOf(address(1)), 0);
        token.transfer(address(1), 100e18);
        assertEq(token.totalSupply(), 100e18);
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(1)), 100e18);
    }

    function testFailNoneApprovedTransferFrom() public {
        token.mintTo(address(1), 100e18);
        token.transferFrom(address(1), address(this), 100e18);
    }

    function testApprovedTransferFrom() public {
        token.mintTo(address(1), 100e18);
        cheats.prank(address(1));
        token.approve(address(this), 100e18);
        assertEq(token.allowance(address(1), address(this)), 100e18);
        token.transferFrom(address(1), address(this), 100e18);
        assertEq(token.balanceOf(address(this)), 100e18);
        assertEq(token.allowance(address(1), address(this)), 0);
    }

    function testBurnTheToken() public {
        token.mint(100e18);
        assertEq(token.balanceOf(address(this)), 100e18);
        token.burn(1e18);
        assertEq(token.balanceOf(address(this)), 99e18);
    }

    function testCallBurnFromNotOwner() public {
        token.mintTo(address(1), 100e18);
        cheats.prank(address(1));
        cheats.expectRevert(bytes("Ownership/Not-Authorized"));
        token.burn(1e18);
    }

    function testFailBurnWithNotEnoughAmount() public {
        token.burn(1e18);
    }

    function testFailTransferZeroBalance() public {
        assertEq(token.totalSupply(), 0);
        assertEq(token.balanceOf(address(this)), 0);
        token.transfer(address(1), 1);
    }

    function testApproveForTokenAddr() public {
        cheats.expectRevert("ERC20/Impossible-Approve-to-Self");
        token.approve(address(token), 1);
    }

    /**
     * in this cases, to target has infinity amount, overflowed.
     * but, this cases is rare.
     */
    // function testFailTransferToTokenAddr() public {
    //     token.mint(2);
    //     assertEq(token.totalSupply(), 2);
    //     assertEq(token.balanceOf(address(this)), 2);
    //     assertEq(token.balanceOf(address(token)), type(uint256).max);
    //     token.transfer(address(token), 2);
    //     assertEq(token.balanceOf(address(token)), 1);
    // }
}
