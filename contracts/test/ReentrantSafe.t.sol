/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "../library/ReentrantSafe.sol";

interface CheatCodes {
    function expectRevert(bytes calldata) external;
}

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

contract ReentrantSafeTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    ReentrantMock r;

    function setUp() public {
        r = new ReentrantMock();
    }

    function testReentrantSaferWithReentrant() public {
        cheats.expectRevert(abi.encodeWithSelector(bytes4(keccak256("RentrantSafe__Reentrant()"))));
        r.selfRecall();
    }

    function testReentrantSaferWithRange() public {
        cheats.expectRevert(abi.encodeWithSelector(bytes4(keccak256("RentrantSafe__Reentrant()"))));
        r.selfRecallWithRange();
    }

    function testReentrantSaferWithWrong() public {
        cheats.expectRevert(abi.encodeWithSelector(bytes4(keccak256("RentrantSafe__Reentrant()"))));
        r.selfRecallWithWrong();
    }

    function testReentrantSafer() public {
        r.justcall();
    }

    function testReentrantSaferRange() public {
        r.justcallWithRange();
    }
}
