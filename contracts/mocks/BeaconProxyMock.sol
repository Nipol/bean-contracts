/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../library/BeaconProxy.sol";

contract BeaconProxyMock {
    address private template;

    constructor(address templateAddr) {
        template = templateAddr;
    }

    function deploy(bytes32 seed) external returns (address addr) {
        addr = BeaconProxy.deploy(template, seed);
    }

    function deploy(string calldata _name, bytes32 seed) external returns (address addr) {
        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), _name);
        addr = BeaconProxy.deploy(template, seed);
        (bool success, ) = addr.call(initCode);
        assert(success);
    }

    function deploy(bytes calldata initcode, bytes32 seed) external returns (address addr) {
        addr = BeaconProxy.deploy(template, seed);
        (bool success, ) = addr.call(initcode);
        assert(success);
    }

    function deployIncrement() external returns (address addr) {
        (bytes32 seed, ) = BeaconProxy.seedSearch(template);
        addr = BeaconProxy.deploy(template, seed);
    }

    function calculateIncrement() external view returns (bytes32 seed, address addr) {
        (seed, addr) = BeaconProxy.seedSearch(template);
    }

    function deployCalculate(bytes32 seed) external view returns (address addr) {
        addr = BeaconProxy.computeAddress(template, seed);
    }

    function isBeacon(address _template, address target) external view returns (bool result) {
        result = BeaconProxy.isBeacon(_template, target);
    }

    function isBeacon(address target) external view returns (bool result) {
        result = BeaconProxy.isBeacon(target);
    }
}
