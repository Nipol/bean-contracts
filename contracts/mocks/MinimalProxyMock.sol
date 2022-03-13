/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../library/MinimalProxy.sol";

contract MinimalProxyMock {
    address private template;

    constructor(address templateAddr) {
        template = templateAddr;
    }

    function deploy(bytes32 seed) external returns (address addr) {
        addr = MinimalProxy.deploy(template, seed);
    }

    function deploy(string calldata _name, bytes32 seed) external returns (address addr) {
        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), _name);
        addr = MinimalProxy.deploy(template, seed);
        (bool success, ) = addr.call(initCode);
        assert(success);
    }

    function deploy(bytes calldata initcode, bytes32 seed) external returns (address addr) {
        addr = MinimalProxy.deploy(template, seed);
        (bool success, ) = addr.call(initcode);
        assert(success);
    }

    function deployIncrement() external returns (address addr) {
        (bytes32 seed, ) = MinimalProxy.seedSearch(template);
        addr = MinimalProxy.deploy(template, seed);
    }

    function calculateIncrement() external view returns (bytes32 seed, address addr) {
        (seed, addr) = MinimalProxy.seedSearch(template);
    }

    function deployCalculate(bytes32 seed) external view returns (address addr) {
        addr = MinimalProxy.computeAddress(template, seed);
    }

    function isMinimal(address _template, address target) external view returns (bool result) {
        result = MinimalProxy.isMinimal(_template, target);
    }

    function isMinimal(address target) external view returns (bool result) {
        result = MinimalProxy.isMinimal(target);
    }
}
