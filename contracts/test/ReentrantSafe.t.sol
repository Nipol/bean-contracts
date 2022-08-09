/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../library/ReentrantSafe.sol";


contract ReentrantMock is ReentrantSafe {
    function justcall() public reentrantSafer {}

    function justcallWithRange() public reentrantStart reentrantEnd {}

    function selfRecall() public reentrantSafer {
        this.selfRecall();
    }

    function selfRecallWithRange() public reentrantStart reentrantEnd {
        this.selfRecallWithRange();
    }

    function selfRecallWithWrong() public reentrantEnd reentrantStart {
        this.selfRecallWithWrong();
    }
}

contract ReentrantSafeTest is Test {
    ReentrantMock r;

    function setUp() public {
        r = new ReentrantMock();
    }

    function testReentrantSaferWithReentrant() public {
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("RentrantSafe__Reentrant()"))));
        r.selfRecall();
    }

    function testReentrantSaferWithRange() public {
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("RentrantSafe__Reentrant()"))));
        r.selfRecallWithRange();
    }

    function testReentrantSaferWithWrong() public {
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("RentrantSafe__Reentrant()"))));
        r.selfRecallWithWrong();
    }

    function testReentrantSafer() public {
        r.justcall();
    }

    function testReentrantSaferRange() public {
        r.justcallWithRange();
    }
}
