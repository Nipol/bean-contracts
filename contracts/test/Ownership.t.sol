/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../library/Ownership.sol";

contract OwnershipT is Ownership {}

contract OwnershipTest is Test {
    OwnershipT o;

    function setUp() public {
        o = new OwnershipT();
    }

    function testInitialOwner() public {
        assertEq(o.owner(), 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);
    }

    function testTransferOwnership() public {
        assertEq(o.owner(), 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);
        o.transferOwnership(address(10));
        assertEq(o.owner(), address(10));
    }

    function testTransferOwnershipToZero() public {
        assertEq(o.owner(), 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("ERC173__NotAllowedTo(address)")), address(0)));
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
        o.transferOwnership(address(10));
    }

    function testCallTransferOwnershipFromZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("ERC173__NotAuthorized(address)")), address(0)));
        vm.prank(address(0));
        o.transferOwnership(address(10));
    }

    function testFailTransferToZero() public {
        assertEq(o.owner(), 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84);
        o.transferOwnership(address(0));
    }
}
