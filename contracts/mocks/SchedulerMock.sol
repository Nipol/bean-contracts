/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../library/Scheduler.sol";

/**
 * @title SchedulerMock
 * @author yoonsung.eth
 * @notice Contract가 할 수 있는 모든 호출을 담당함.
 */
contract SchedulerMock is Scheduler {
    uint32 internal constant GRACE_PERIOD = 7 days;
    uint32 internal constant MINIMUM_DELAY = 1 days;
    uint32 internal constant MAXIMUM_DELAY = 30 days;

    string public name = "Scheduler";

    function set(uint32 delayTime) external {
        setDelay(delayTime, MINIMUM_DELAY, MAXIMUM_DELAY);
    }

    function set2(uint32 delayTime) external {
        setDelay(delayTime, MAXIMUM_DELAY, MINIMUM_DELAY);
    }

    function _queue(bytes32 uid) external {
        queue(uid);
    }

    function _queue(bytes32 uid, uint32 time) external {
        queue(uid, time);
    }

    function _resolve(bytes32 uid) external {
        resolve(uid, GRACE_PERIOD);
    }
}
