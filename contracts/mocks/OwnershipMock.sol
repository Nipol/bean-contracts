/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../library/Ownership.sol";
import "../interfaces/IERC173.sol";

contract OwnershipMock is IERC173, Ownership {
    constructor() {
        Ownership.initialize(msg.sender);
    }
}
