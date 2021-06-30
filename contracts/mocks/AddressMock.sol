/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../Library/Address.sol";

contract AddressMock {
    using Address for address;

    function isContract(address target) external view returns (bool result) {
        result = target.isContract();
    }
}
