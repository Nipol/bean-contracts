// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "../library/Address.sol";

contract AddressTest is DSTest {
    using Address for address;

    function setUp() public {}

    function testCallerAddress() public {
        assertTrue(address(this).isContract());
    }

    function testSpecificAddress() public {
        assertTrue(!address(1).isContract());
    }

    
}
