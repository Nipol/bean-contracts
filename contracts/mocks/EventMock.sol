/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

contract EventMock {
    event EmittedString(string);

    function emitString(string memory str) external {
        emit EmittedString(str);
    }
}
