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

    function deploy() external returns (address addr) {
        addr = MinimalProxyDeployer.deploy(template, new bytes(0));
    }

    function deploy(string calldata _name) external returns (address addr) {
        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), _name);
        addr = MinimalProxyDeployer.deploy(template, initCode);
    }

    function deployCalculate() external view returns (address addr) {
        addr = MinimalProxyDeployer.calculateAddress(template, new bytes(0));
    }

    function deployCalculate(string calldata _name) external view returns (address addr) {
        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), _name);
        addr = MinimalProxyDeployer.calculateAddress(template, initCode);
    }

    function deployFromSeed() external returns (address addr) {
        addr = MinimalProxyDeployer.deploy(seed, template, new bytes(0));
    }

    function deployFromSeed(string calldata _name) external returns (address addr) {
        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), _name);
        addr = MinimalProxyDeployer.deploy(seed, template, initCode);
    }

    function deployCalculateFromSeed() external view returns (address addr) {
        addr = MinimalProxyDeployer.calculateAddress(seed, template, new bytes(0));
    }

    function deployCalculateFromSeed(string calldata _name) external view returns (address addr) {
        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), _name);
        addr = MinimalProxyDeployer.calculateAddress(seed, template, initCode);
    }

    function isMinimal(address target) external view returns (bool result) {
        result = MinimalProxyDeployer.isMinimal(template, target);
    }
}
