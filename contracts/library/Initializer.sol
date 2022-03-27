/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

error AlreadyInitialized();

/**
 * @title Initializer
 * @author yoonsung.eth
 * @notice After the contract is deployed, you can configure a function that can only be called once.
 */
abstract contract Initializer {
    bool private _initialized;

    modifier initializer() {
        if (_initialized && (address(this).code.length != 0)) revert AlreadyInitialized();
        _initialized = true;
        _;
    }
}
