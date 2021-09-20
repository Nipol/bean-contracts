/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

interface IAggregatecall {
    struct Call {
        address target;
        bytes data;
    }

    function aggregate(Call[] memory calls) external returns (bytes[] memory returnData);
}