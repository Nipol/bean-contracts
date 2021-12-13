/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

contract VaultMock {
    event Received(address sender, uint256 amount);

    function save() external payable {
        emit Received(msg.sender, msg.value);
    }
}
