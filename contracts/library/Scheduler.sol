/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../interfaces/IScheduler.sol";

error Scheduler__DelayIsNotRange();

error Scheduler__AlreadyQueued(bytes32 taskId);

error Scheduler__NotQueued(bytes32 taskId);

error Scheduler__RemainingTime(bytes32 taskId);

/**
 * @title Scheduler
 * @author yoonsung.eth
 * @notice Manage task-level scheduling at the time specified by the user.
 */
abstract contract Scheduler is IScheduler {
    uint32 public delay = type(uint32).max;
    mapping(bytes32 => Task) public taskOf;

    function setDelay(
        uint32 delayValue,
        uint32 minimumDelay,
        uint32 maximumDelay
    ) internal {
        if (delayValue < minimumDelay || delayValue > maximumDelay || minimumDelay > maximumDelay)
            revert Scheduler__DelayIsNotRange();
        delay = delayValue;
        emit Delayed(delayValue);
    }

    function queue(bytes32 taskid) internal {
        queue(taskid, uint32(block.timestamp));
    }

    function queue(bytes32 taskid, uint32 from) internal {
        if (taskOf[taskid].state != STATE.UNKNOWN) revert Scheduler__AlreadyQueued(taskid);
        assert(from >= uint32(block.timestamp));
        uint32 total = from + delay;
        (taskOf[taskid].endTime, taskOf[taskid].state) = (total, STATE.QUEUED);
        emit Queued(taskid, total);
    }

    function resolve(bytes32 taskid, uint32 gracePeriod) internal {
        Task memory t = taskOf[taskid];
        if (t.state != STATE.QUEUED) revert Scheduler__NotQueued(taskid);
        if (t.endTime > uint32(block.timestamp)) revert Scheduler__RemainingTime(taskid);

        if (uint32(block.timestamp) >= t.endTime + gracePeriod) {
            (taskOf[taskid].endTime, taskOf[taskid].state) = (0, STATE.STALED);
            emit Staled(taskid);
        } else {
            (taskOf[taskid].endTime, taskOf[taskid].state) = (0, STATE.RESOLVED);
            emit Resolved(taskid);
        }
    }
}
