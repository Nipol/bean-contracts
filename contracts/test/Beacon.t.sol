// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "../library/BeaconDeployer.sol";

interface CheatCodes {
    function prank(address) external;
}

contract BeaconTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    address deployed;

    function setUp() public {
        deployed = BeaconDeployer.deploy(address(1));
    }

    function testUpgrade() public {
        bool success;
        bytes memory data;
        bytes memory newAddr = abi.encode(address(9));
        (success, ) = deployed.call(newAddr);
        assertTrue(success);

        cheats.prank(address(3));
        (success, data) = deployed.staticcall(data);
        assertTrue(success);
        assertEq(bytes32(data), 0x0000000000000000000000000000000000000000000000000000000000000009);
    }

    function testFailUpgradeFromNotOwner() public {
        bool success;
        bytes memory data;
        bytes memory newAddr = abi.encode(address(5));
        cheats.prank(address(1));
        (success, ) = deployed.call(newAddr);

        (success, data) = deployed.staticcall(data);
        assertTrue(success);
        assertEq(bytes32(data), 0x0000000000000000000000000000000000000000000000000000000000000001);

    }
}
