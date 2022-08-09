/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IMulticall, Multicall} from "../library/Multicall.sol";

contract MulticallTest is Multicall, Test {
    uint256 public counter;

    function setUp() public {
        counter = 0;
    }

    function increase() public {
        counter++;
    }

    function decrease() public {
        counter--;
    }

    function revertCall() public pure {
        revert("Message From Revert");
    }

    function emptyRevertCall() public pure {
        revert();
    }

    function test3TimesCall() public {
        bytes memory cd = abi.encodeWithSelector(bytes4(keccak256("increase()")));
        bytes[] memory cds = new bytes[](3);

        (cds[0], cds[1], cds[2]) = (cd, cd, cd);
        IMulticall(address(this)).multicall(cds);

        assertEq(counter, 3);
    }

    function test6TimesCall() public {
        bytes memory cd = abi.encodeWithSelector(bytes4(keccak256("increase()")));
        bytes[] memory cds = new bytes[](6);

        (cds[0], cds[1], cds[2], cds[3], cds[4], cds[5]) = (cd, cd, cd, cd, cd, cd);

        IMulticall(address(this)).multicall(cds);

        assertEq(counter, 6);
    }

    function testRevertCaseCall() public {
        bytes memory cd = abi.encodeWithSelector(bytes4(keccak256("decrease()")));
        bytes[] memory cds = new bytes[](1);
        (cds[0]) = (cd);

        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("Panic(uint256)")), 0x11));
        IMulticall(address(this)).multicall(cds);
    }

    function testRevertMessageCaseCall() public {
        bytes memory cd = abi.encodeWithSelector(bytes4(keccak256("revertCall()")));
        bytes[] memory cds = new bytes[](1);

        (cds[0]) = (cd);

        vm.expectRevert(bytes("Message From Revert"));
        IMulticall(address(this)).multicall(cds);
    }

    function testEmptyRevertMessageCaseCall() public {
        bytes memory cd = abi.encodeWithSelector(bytes4(keccak256("emptyRevertCall()")));
        bytes[] memory cds = new bytes[](1);

        (cds[0]) = (cd);

        vm.expectRevert(bytes(""));
        IMulticall(address(this)).multicall(cds);
    }
}
