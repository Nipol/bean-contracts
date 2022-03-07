/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../library/BeaconProxy.sol";

contract BeaconDeployMock {
    address private beacon;

    constructor(address beaconAddr) {
        beacon = beaconAddr;
    }

    function deploy() external returns (address addr) {
        (bytes32 seed, ) = BeaconProxy.seedSearch(addr);
        addr = BeaconProxy.deploy(beacon, seed);
    }

    function deploy(string calldata _name) external returns (address addr) {
        (bytes32 seed, ) = BeaconProxy.seedSearch(addr);
        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), _name);
        addr = BeaconProxy.deploy(beacon, seed);
        addr.call(initCode);
    }

    function deployCalculate() external view returns (address addr) {
        (bytes32 seed, ) = BeaconProxy.seedSearch(addr);
        addr = BeaconProxy.computeAddress(beacon, seed);
    }

    function deployFromSeed(bytes32 seed) external returns (address addr) {
        addr = BeaconProxy.deploy(beacon, seed);
    }

    function deployFromSeed(bytes32 seed, string calldata _name) external returns (address addr) {
        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), _name);
        addr = BeaconProxy.deploy(beacon, seed);
        addr.call(initCode);
    }

    function deployCalculateFromSeed(bytes32 seed) external view returns (address addr) {
        addr = BeaconProxy.computeAddress(beacon, seed);
    }

    function isBeacon(address target) external view returns (bool result) {
        result = BeaconProxy.isBeacon(beacon, target);
    }
}
