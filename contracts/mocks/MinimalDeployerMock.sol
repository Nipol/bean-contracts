/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../library/MinimalProxyDeployer.sol";

contract MinimalDeployerMock {
    string private seed;
    address private template;

    constructor(address templateAddr, string memory seedStr) {
        template = templateAddr;
        seed = seedStr;
    }

    function deploy(string calldata _name) external returns (address addr) {
        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), _name);

        addr = MinimalProxyDeployer.deploy(template, initCode);
    }

    function deployCalculate(string calldata _name) external view returns (address addr) {
        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), _name);

        addr = MinimalProxyDeployer.calculateAddress(template, initCode);
    }

    function deployFromSeed(string calldata _name) external returns (address addr) {
        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), _name);

        addr = MinimalProxyDeployer.deployFromSeed(template, initCode, seed);
    }

    function deployCalculateFromSeed(string calldata _name) external view returns (address addr) {
        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), _name);

        addr = MinimalProxyDeployer.calculateAddressFromSeed(template, initCode, seed);
    }

    function isMinimal(address target) external view returns (bool result) {
        result = MinimalProxyDeployer.isMinimal(template, target);
    }
}
