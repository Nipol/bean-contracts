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
    string public name = "Scheduler";

    function set(uint32 delayTime) external {
        setDelay(delayTime);
    }

    function _queue(bytes32 uid) external {
        queue(uid);
    }

    function _resolve(bytes32 uid) external {
        resolve(uid);
    }
}
