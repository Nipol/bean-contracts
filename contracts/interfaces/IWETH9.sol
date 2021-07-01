/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

interface IWETH9 {
    function deposit() external payable;
    function withdraw(uint256) external;
}
