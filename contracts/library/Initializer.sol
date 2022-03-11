/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

abstract contract Initializer {
    bool private _initialized;

    modifier initializer() {
        require(!_initialized || !(address(this).code.length != 0), "Initializer/Already Initialized");
        _initialized = true;
        _;
    }
}
