/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

/**
 * @title IScheduler
 * @author yoonsung.eth
 * @notice Contract가 할 수 있는 모든 호출을 담당함.
 */
interface IScheduler {
    enum STATE {
        UNKNOWN,
        QUEUED,
        RESOLVED,
        STALED
    }

    struct Task {
        uint32 endTime;
        STATE state;
    }

    event Delayed(uint32 delay);
    event Queued(bytes32 indexed taskId, uint32 delay);
    event Resolved(bytes32 indexed taskId);
    event Staled(bytes32 indexed taskId);
}
