/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../library/Wizadry.sol";

contract WizadryMock is Wizadry {
    receive() external payable {}

    function _cast(bytes32[] calldata spells, bytes[] memory elements) external returns (bytes[] memory) {
        return cast(spells, elements);
    }
}
