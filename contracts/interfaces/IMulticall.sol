/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

interface IMulticall {
    function multicall(bytes[] calldata callData) external returns (bytes[] memory returnData);
}
