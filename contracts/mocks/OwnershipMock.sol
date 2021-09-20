/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../library/Ownership.sol";
import "../interfaces/IERC173.sol";

contract OwnershipMock1 is IERC173, Ownership {
    event Sample();

    constructor() {}

    function trigger() external onlyOwner {
        emit Sample();
    }
}

contract OwnershipMock2 is IERC173, Ownership {
    event Sample();

    function initialize() public {
        _transferOwnership(msg.sender);
    }

    function trigger() external onlyOwner {
        emit Sample();
    }
}
