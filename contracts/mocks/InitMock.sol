/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../library/Initializer.sol";

contract InitMock is Initializer {
    function initialize() external initializer returns (bool) {
        return true;
    }
}
