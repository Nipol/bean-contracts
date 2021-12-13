/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

contract EventSpell {
    event EmittedString(string);
    event EmittedAddress(address);

    function emitString(string memory str) external {
        emit EmittedString(str);
    }

    function emitAddress(address addr) external {
        emit EmittedAddress(addr);
    }
}
