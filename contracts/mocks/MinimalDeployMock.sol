/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../library/MinimalProxy.sol";

contract MinimalDeployMock {
    address private template;

    constructor(address templateAddr) {
        template = templateAddr;
    }

    function deploy() external returns (address addr) {
        (bytes32 seed, ) = MinimalProxy.seedSearch(addr);
        addr = MinimalProxy.deploy(template, seed);
    }

    function deploy(string calldata _name) external returns (address addr) {
        (bytes32 seed, ) = MinimalProxy.seedSearch(addr);
        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), _name);
        addr = MinimalProxy.deploy(template, seed);
        addr.call(initCode);
    }

    function deployCalculate() external view returns (address addr) {
        (bytes32 seed, ) = MinimalProxy.seedSearch(addr);
        addr = MinimalProxy.computeAddress(template, seed);
    }

    function deployFromSeed(bytes32 seed) external returns (address addr) {
        addr = MinimalProxy.deploy(template, seed);
    }

    function deployFromSeed(bytes32 seed, string calldata _name) external returns (address addr) {
        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), _name);
        addr = MinimalProxy.deploy(template, seed);
        addr.call(initCode);
    }

    function deployCalculateFromSeed(bytes32 seed) external view returns (address addr) {
        addr = MinimalProxy.computeAddress(template, seed);
    }

    function isMinimal(address target) external view returns (bool result) {
        result = MinimalProxy.isMinimal(template, target);
    }
}
