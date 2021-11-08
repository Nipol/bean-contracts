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
        APPROVED,
        RESOLVED,
        STALED
    }

    event Delayed(uint32 delay);
    event Approved(bytes32 indexed id, uint32 delay);
    event Resolved(bytes32 indexed id);
    event Staled(bytes32 indexed id);
}
