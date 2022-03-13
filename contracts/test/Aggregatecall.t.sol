/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "ds-test/test.sol";
import {IAggregatecall, Aggregatecall} from "../library/Aggregatecall.sol";

interface CheatCodes {
    function prank(address) external;

    function expectRevert(bytes calldata) external;
}

contract Encounter {
    uint256 public counter;

    function increase() external {
        counter++;
    }

    function decrease() external {
        counter--;
    }

    function revertCall() external pure {
        revert("Message From Revert");
    }

    function emptyRevertCall() external pure {
        revert();
    }
}

contract AggregateCaller is Aggregatecall {}

contract AggregatecallTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    Encounter c;
    IAggregatecall ac;

    function setUp() public {
        c = new Encounter();
        ac = new AggregateCaller();
    }

    function test3TimesCall() public {
        IAggregatecall.Call memory cd = IAggregatecall.Call({
            target: address(c),
            data: abi.encodeWithSelector(bytes4(keccak256("increase()")))
        });

        IAggregatecall.Call[] memory cds = new IAggregatecall.Call[](3);
        (cds[0], cds[1], cds[2]) = (cd, cd, cd);

        ac.aggregate(cds);

        assertEq(c.counter(), 3);
    }

    function test6TimesCall() public {
        IAggregatecall.Call memory cd = IAggregatecall.Call({
            target: address(c),
            data: abi.encodeWithSelector(bytes4(keccak256("increase()")))
        });

        IAggregatecall.Call[] memory cds = new IAggregatecall.Call[](6);
        (cds[0], cds[1], cds[2], cds[3], cds[4], cds[5]) = (cd, cd, cd, cd, cd, cd);

        ac.aggregate(cds);

        assertEq(c.counter(), 6);
    }

    function testFailRevertCaseCall() public {
        IAggregatecall.Call memory cd = IAggregatecall.Call({
            target: address(c),
            data: abi.encodeWithSelector(bytes4(keccak256("decrease()")))
        });

        IAggregatecall.Call[] memory cds = new IAggregatecall.Call[](1);
        (cds[0]) = (cd);

        ac.aggregate(cds);
    }

    function testRevertMessageCaseCall() public {
        IAggregatecall.Call memory cd = IAggregatecall.Call({
            target: address(c),
            data: abi.encodeWithSelector(bytes4(keccak256("revertCall()")))
        });

        IAggregatecall.Call[] memory cds = new IAggregatecall.Call[](1);
        (cds[0]) = (cd);

        cheats.expectRevert(bytes("Message From Revert"));
        ac.aggregate(cds);
    }

    function testEmptyRevertMessageCaseCall() public {
        IAggregatecall.Call memory cd = IAggregatecall.Call({
            target: address(c),
            data: abi.encodeWithSelector(bytes4(keccak256("emptyRevertCall()")))
        });

        IAggregatecall.Call[] memory cds = new IAggregatecall.Call[](1);
        (cds[0]) = (cd);

        cheats.expectRevert(bytes(""));
        ac.aggregate(cds);
    }
}
