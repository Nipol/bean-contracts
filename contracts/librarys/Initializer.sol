/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "./Address.sol";

abstract contract Initializer {
    using Address for address;

    bool private _initialized;
    bool private _initializing;

    modifier initializer() {
        require(
            _initializing || !_initialized || !address(this).isContract(),
            "Initializer/Already Initialized"
        );

        bool isSurfaceCall = !_initializing;
        if (isSurfaceCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isSurfaceCall) {
            _initializing = false;
        }
    }
}
