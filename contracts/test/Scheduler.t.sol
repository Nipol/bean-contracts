/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IScheduler, Scheduler} from "../library/Scheduler.sol";

contract SchedulerMock is Scheduler {
    function set(
        uint32 delayTime,
        uint32 minimum,
        uint32 maximum
    ) external {
        setDelay(delayTime, minimum, maximum);
    }

    function setQueue(bytes32 uid) external {
        queue(uid);
    }

    function setQueue(bytes32 uid, uint32 time) external {
        queue(uid, time);
    }

    function setResolve(bytes32 uid, uint32 grace) external {
        resolve(uid, grace);
    }
}

contract SchedulerTest is Scheduler, Test {
    SchedulerMock sch;

    function setUp() public {
        sch = new SchedulerMock();
        vm.warp(1);
    }

    uint32 internal constant GRACE_PERIOD = 1 days;
    uint32 internal constant MINIMUM_DELAY = 1 days;
    uint32 internal constant MAXIMUM_DELAY = 30 days;

    function testDelaySet() public {
        sch.set(2 days, MINIMUM_DELAY, MAXIMUM_DELAY);
        assertEq(sch.delay(), 2 days);
    }

    function testDelaySetWithWrongRange() public {
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("Scheduler__DelayIsNotRange()"))));
        sch.set(2 days, MAXIMUM_DELAY, MINIMUM_DELAY);
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("Scheduler__DelayIsNotRange()"))));
        sch.set(32 days, MINIMUM_DELAY, MAXIMUM_DELAY);
    }

    function testFailNotInitializedQueue() public {
        sch.setQueue(0x0000000000000000000000000000000000000000000000000000000000000001);
    }

    function testQueue() public {
        sch.set(2 days, MINIMUM_DELAY, MAXIMUM_DELAY);
        sch.setQueue(0x0000000000000000000000000000000000000000000000000000000000000001);
        (uint32 et, IScheduler.STATE state) = sch.taskOf(
            0x0000000000000000000000000000000000000000000000000000000000000001
        );
        assertEq(et, 1 + 60 * 60 * 24 * 2);
        assertEq(uint256(state), 1);
    }

    function testAlreadyQueued() public {
        sch.set(2 days, MINIMUM_DELAY, MAXIMUM_DELAY);
        sch.setQueue(0x0000000000000000000000000000000000000000000000000000000000000001);
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("Scheduler__AlreadyQueued(bytes32)")),
                0x0000000000000000000000000000000000000000000000000000000000000001
            )
        );
        sch.setQueue(0x0000000000000000000000000000000000000000000000000000000000000001);
    }

    function testFailPastTask() public {
        sch.setQueue(0x0000000000000000000000000000000000000000000000000000000000000001, 0);
        (, IScheduler.STATE state) = sch.taskOf(0x0000000000000000000000000000000000000000000000000000000000000001);
        assertEq(uint256(state), 0);
    }

    function testNotQueuedTaskResolve() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("Scheduler__NotQueued(bytes32)")),
                0x0000000000000000000000000000000000000000000000000000000000000001
            )
        );
        sch.setResolve(0x0000000000000000000000000000000000000000000000000000000000000001, GRACE_PERIOD);
    }

    function testNotReachedTask() public {
        sch.set(2 days, MINIMUM_DELAY, MAXIMUM_DELAY);
        sch.setQueue(0x0000000000000000000000000000000000000000000000000000000000000001);

        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("Scheduler__RemainingTime(bytes32)")),
                0x0000000000000000000000000000000000000000000000000000000000000001
            )
        );
        sch.setResolve(0x0000000000000000000000000000000000000000000000000000000000000001, GRACE_PERIOD);
    }

    function testResolvableTask() public {
        sch.set(2 days, MINIMUM_DELAY, MAXIMUM_DELAY);
        sch.setQueue(0x0000000000000000000000000000000000000000000000000000000000000001);

        vm.warp(1 + 60 * 60 * 24 * 2);
        sch.setResolve(0x0000000000000000000000000000000000000000000000000000000000000001, GRACE_PERIOD);

        (uint32 et, IScheduler.STATE state) = sch.taskOf(
            0x0000000000000000000000000000000000000000000000000000000000000001
        );
        assertEq(et, 0);
        assertEq(uint256(state), 2);
    }

    function testResolveAfterGracePeriod() public {
        sch.set(2 days, MINIMUM_DELAY, MAXIMUM_DELAY);
        sch.setQueue(0x0000000000000000000000000000000000000000000000000000000000000001);

        vm.warp(1 + 60 * 60 * 24 * 4);
        sch.setResolve(0x0000000000000000000000000000000000000000000000000000000000000001, GRACE_PERIOD);

        (uint32 et, IScheduler.STATE state) = sch.taskOf(
            0x0000000000000000000000000000000000000000000000000000000000000001
        );
        assertEq(et, 0);
        assertEq(uint256(state), 3);
    }
}
