/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract IsContractTest is Test {
    function setUp() public {}

    function testCallerAddress() public {
        assertTrue(address(this).code.length != 0);
    }

    function testSpecificAddress() public {
        bool result;
        address target = address(10);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := gt(extcodesize(target), 0)
        }
        assertTrue(!result);
    }
}
