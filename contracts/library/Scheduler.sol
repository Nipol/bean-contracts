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
    uint32 internal constant GRACE_PERIOD = 7 days;
    uint32 internal constant MINIMUM_DELAY = 1 days;
    uint32 internal constant MAXIMUM_DELAY = 30 days;

    uint32 public delay;
    mapping(bytes32 => uint32) public endOf;
    mapping(bytes32 => STATE) public stateOf;

    function setDelay(uint32 value) internal {
        require(value >= MINIMUM_DELAY && value <= MAXIMUM_DELAY, "Scheduler/Delay-is-not-within-Range");
        delay = value;
        emit Delayed(value);
    }

    function queue(bytes32 uid) internal {
        queue(uid, uint32(block.timestamp));
    }

    function queue(bytes32 uid, uint32 from) internal {
        require(stateOf[uid] == STATE.UNKNOWN, "Scheduler/Already-Scheduled");
        assert(from >= uint32(block.timestamp));
        endOf[uid] = from + delay;
        stateOf[uid] = STATE.APPROVED;
        emit Approved(uid, from + delay);
    }

    function resolve(bytes32 uid) internal {
        require(stateOf[uid] == STATE.APPROVED, "Scheduler/Not-Queued");
        require(uint32(block.timestamp) >= endOf[uid], "Scheduler/Not-Reached-Lock");

        if (uint32(block.timestamp) >= endOf[uid] + GRACE_PERIOD) {
            delete endOf[uid];
            stateOf[uid] = STATE.STALED;
            emit Staled(uid);
        } else {
            delete endOf[uid];
            stateOf[uid] = STATE.RESOLVED;
            emit Resolved(uid);
        }
    }
}
