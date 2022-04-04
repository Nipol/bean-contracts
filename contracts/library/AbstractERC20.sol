/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

abstract contract AbstractERC20 {
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal virtual;
}
