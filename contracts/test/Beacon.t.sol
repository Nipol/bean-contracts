/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../library/BeaconDeployer.sol";

contract BeaconTest is Test {
    address deployed;

    function setUp() public {
        deployed = BeaconDeployer.deploy(address(10));
    }

    function testUpgrade() public {
        bool success;
        bytes memory data;
        bytes memory newAddr = abi.encode(address(9));
        (success, ) = deployed.call(newAddr);
        assertTrue(success);

        vm.prank(address(3));
        (success, data) = deployed.staticcall(data);
        assertTrue(success);
        assertEq(bytes32(data), 0x0000000000000000000000000000000000000000000000000000000000000009);
    }

    function testFailUpgradeFromNotOwner() public {
        bool success;
        bytes memory data;
        bytes memory newAddr = abi.encode(address(5));
        vm.prank(address(10));
        (success, ) = deployed.call(newAddr);

        (success, data) = deployed.staticcall(data);
        assertTrue(success);
        assertEq(bytes32(data), 0x0000000000000000000000000000000000000000000000000000000000000001);

    }
}
