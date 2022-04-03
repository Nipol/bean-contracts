/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "ds-test/test.sol";
import {WETH, IERC20, IERC165, IERC2612} from "../library/WETH.sol";

interface CheatCodes {
    function prank(address) external;

    function expectRevert(bytes calldata) external;

    function deal(address who, uint256 newBalance) external;
}

contract WETHTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    WETH weth;

    receive() external payable {}

    function setUp() public {
        weth = new WETH();
        cheats.deal(address(this), 1 ether);
    }

    function testFailDepositWithTransfer() public {
        // cheats.expectRevert(
        //     abi.encodeWithSelector(
        //         bytes4(keccak256("Error(string)")),
        //         bytes("Call reverted as expected, but without data")
        //     )
        // );
        payable(weth).transfer(1 ether);
    }

    function testDepositWithReceiveFallback() public {
        assertEq(weth.balanceOf(address(this)), 0);
        assertEq(weth.totalSupply(), 0);

        // no transfer and send. they used only 2,300 gas.
        address(weth).call{value: 1 ether}("");
        // weth.deposit{value: 1 ether}();

        assertEq(weth.balanceOf(address(this)), 1 ether);
        assertEq(weth.totalSupply(), 1 ether);
    }

    function testDepositFunction() public {
        assertEq(weth.balanceOf(address(this)), 0);
        assertEq(weth.totalSupply(), 0);

        weth.deposit{value: 1 ether}();

        assertEq(weth.balanceOf(address(this)), 1 ether);
        assertEq(weth.totalSupply(), 1 ether);
    }

    function testWithdraw() public {
        weth.deposit{value: 1 ether}();

        assertEq(weth.balanceOf(address(this)), 1 ether);
        assertEq(weth.totalSupply(), 1 ether);

        weth.withdraw(1 ether);

        assertEq(weth.balanceOf(address(this)), 0);
        assertEq(weth.totalSupply(), 0);
    }

    function testWithdrawWithNotEnoughBalance() public {
        cheats.expectRevert(abi.encodeWithSelector(bytes4(keccak256("Panic(uint256)")), 0x11));
        weth.withdraw(1 ether);
    }
}
