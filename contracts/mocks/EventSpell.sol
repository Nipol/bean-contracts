/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

contract EventSpell {
    event EmittedString(string);
    event EmittedAddress(address);
    event EmittedBool(bool);
    event EmittedBytes32(bytes32);

    function emitString(string memory str) external {
        emit EmittedString(str);
    }

    function emitAddress(address addr) external {
        emit EmittedAddress(addr);
    }

    function emitBool(bool b) external {
        emit EmittedBool(b);
    }

    function emitBytes32(bytes32 data) external {
        emit EmittedBytes32(data);
    }
}
