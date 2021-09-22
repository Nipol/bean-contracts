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

    function deploy() external returns (address addr) {
        addr = BeaconProxyDeployer.deploy(beacon, new bytes(0));
    }

    function deploy(string calldata _name) external returns (address addr) {
        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), _name);

        addr = BeaconProxyDeployer.deploy(beacon, initCode);
    }

    function deployCalculate() external view returns (address addr) {
        addr = BeaconProxyDeployer.calculateAddress(beacon, new bytes(0));
    }

    function deployCalculate(string calldata _name) external view returns (address addr) {
        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), _name);

        addr = BeaconProxyDeployer.calculateAddress(beacon, initCode);
    }

    function deployFromSeed() external returns (address addr) {
        addr = BeaconProxyDeployer.deploy(seed, beacon, new bytes(0));
    }

    function deployFromSeed(string calldata _name) external returns (address addr) {
        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), _name);

        addr = BeaconProxyDeployer.deploy(seed, beacon, initCode);
    }

    function deployCalculateFromSeed() external view returns (address addr) {
        addr = BeaconProxyDeployer.calculateAddress(seed, beacon, new bytes(0));
    }

    function deployCalculateFromSeed(string calldata _name) external view returns (address addr) {
        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), _name);

        addr = BeaconProxyDeployer.calculateAddress(seed, beacon, initCode);
    }

    function isBeacon(address target) external view returns (bool result) {
        result = BeaconProxyDeployer.isBeacon(beacon, target);
    }
}
