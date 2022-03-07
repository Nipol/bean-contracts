// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "../library/Allowlist.sol";

contract AllowlistT is Allowlist {}

contract AllowlistTest is DSTest {
    AllowlistT a;

    function setUp() public {
        a = new AllowlistT();
    }
}
