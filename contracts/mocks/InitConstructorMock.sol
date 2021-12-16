/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../library/Initializer.sol";

contract InitConstructorMock is Initializer {
    constructor() initializer {}

    function initialize() external initializer returns (bool) {
        return true;
    }
}
