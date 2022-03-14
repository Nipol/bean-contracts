/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "../library/Ownership.sol";

interface CheatCodes {
    function prank(address) external;

    function expectRevert(bytes calldata) external;
}

contract OwnershipT is Ownership {}

contract OwnershipTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    OwnershipT o;

    function setUp() public {
        o = new OwnershipT();
    }

    function testInitialOwner() public {
        assertEq(o.owner(), 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);
    }

    function testTransferOwnership() public {
        assertEq(o.owner(), 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);
        o.transferOwnership(address(1));
        assertEq(o.owner(), address(1));
    }

    function testTransferOwnershipToZero() public {
        assertEq(o.owner(), 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);
        cheats.expectRevert(abi.encodeWithSelector(bytes4(keccak256("ERC173_NotAllowedTo(address)")), address(0)));
        o.transferOwnership(address(0));
    }

    function testResignOwnership() public {
        assertEq(o.owner(), 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);
        o.resignOwnership();
        assertEq(o.owner(), address(0));
    }

    function testFailResignAfterTransferOwnership() public {
        assertEq(o.owner(), 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);
        o.resignOwnership();
        o.transferOwnership(address(1));
    }

    function testCallTransferOwnershipFromZeroAddress() public {
        cheats.expectRevert(abi.encodeWithSelector(bytes4(keccak256("ERC173_NotAuthorized(address)")), address(0)));
        cheats.prank(address(0));
        o.transferOwnership(address(1));
    }

    function testFailTransferToZero() public {
        assertEq(o.owner(), 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);
        o.transferOwnership(address(0));
    }
}
