/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../library/BeaconProxyDeployer.sol";

contract BeaconDeployerMock {
    string private seed;
    address private beacon;

    constructor(address beaconAddr, string memory seedStr) {
        beacon = beaconAddr;
        seed = seedStr;
    }

    function deploy(string calldata _name) external returns (address addr) {
        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), _name);

        addr = BeaconProxyDeployer.deploy(beacon, initCode);
    }

    function deployCalculate(string calldata _name) external view returns (address addr) {
        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), _name);

        addr = BeaconProxyDeployer.calculateAddress(beacon, initCode);
    }

    function deployFromSeed(string calldata _name) external returns (address addr) {
        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), _name);

        addr = BeaconProxyDeployer.deployFromSeed(beacon, initCode, seed);
    }

    function deployCalculateFromSeed(string calldata _name) external view returns (address addr) {
        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), _name);

        addr = BeaconProxyDeployer.calculateAddressFromSeed(beacon, initCode, seed);
    }

    function isBeacon(address target) external view returns (bool result) {
        result = BeaconProxyDeployer.isBeacon(beacon, target);
    }
}
