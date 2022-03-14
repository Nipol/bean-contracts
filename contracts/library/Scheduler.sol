/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../interfaces/IScheduler.sol";

error Scheduler_DelayIsNotRange();

error Scheduler_AlreadyQueued(bytes32 taskId);

error Scheduler_NotQueued(bytes32 taskId);

error Scheduler_RemainingTime(bytes32 taskId);

/**
 * @title Scheduler
 * @author yoonsung.eth
 * @notice 컨트랙트에 내부적으로 사용될 시간 지연 모듈
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
            revert Scheduler_DelayIsNotRange();
        delay = delayValue;
        emit Delayed(delayValue);
    }

    function queue(bytes32 taskid) internal {
        queue(taskid, uint32(block.timestamp));
    }

    function queue(bytes32 taskid, uint32 from) internal {
        if (taskOf[taskid].state != STATE.UNKNOWN) revert Scheduler_AlreadyQueued(taskid);
        assert(from >= uint32(block.timestamp));
        uint32 total = from + delay;
        (taskOf[taskid].endTime, taskOf[taskid].state) = (total, STATE.QUEUED);
        emit Queued(taskid, total);
    }

    function resolve(bytes32 taskid, uint32 gracePeriod) internal {
        Task memory t = taskOf[taskid];
        if (t.state != STATE.QUEUED) revert Scheduler_NotQueued(taskid);
        if (t.endTime > uint32(block.timestamp)) revert Scheduler_RemainingTime(taskid);

        if (uint32(block.timestamp) >= t.endTime + gracePeriod) {
            (taskOf[taskid].endTime, taskOf[taskid].state) = (0, STATE.STALED);
            emit Staled(taskid);
        } else {
            (taskOf[taskid].endTime, taskOf[taskid].state) = (0, STATE.RESOLVED);
            emit Resolved(taskid);
        }
    }
}
