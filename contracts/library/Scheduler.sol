/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../interfaces/IScheduler.sol";

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
        require(
            delayValue >= minimumDelay && delayValue <= maximumDelay && minimumDelay < maximumDelay,
            "Scheduler/Delay-is-not-within-Range"
        );
        delay = delayValue;
        emit Delayed(delayValue);
    }

    function queue(bytes32 taskid) internal {
        queue(taskid, uint32(block.timestamp));
    }

    function queue(bytes32 taskid, uint32 from) internal {
        require(taskOf[taskid].state == STATE.UNKNOWN, "Scheduler/Already-Scheduled");
        assert(from >= uint32(block.timestamp));
        uint32 total = from + delay;
        (taskOf[taskid].endTime, taskOf[taskid].state) = (total, STATE.QUEUED);
        emit Queued(taskid, total);
    }

    function resolve(bytes32 taskid, uint32 gracePeriod) internal {
        Task memory t = taskOf[taskid];
        require(t.state == STATE.QUEUED, "Scheduler/Not-Queued");
        require(uint32(block.timestamp) >= t.endTime, "Scheduler/Not-Reached-Lock");

        if (uint32(block.timestamp) >= t.endTime + gracePeriod) {
            (taskOf[taskid].endTime, taskOf[taskid].state) = (0, STATE.STALED);
            emit Staled(taskid);
        } else {
            (taskOf[taskid].endTime, taskOf[taskid].state) = (0, STATE.RESOLVED);
            emit Resolved(taskid);
        }
    }
}
