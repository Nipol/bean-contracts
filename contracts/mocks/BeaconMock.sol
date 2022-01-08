/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../library/BeaconDeployer.sol";

contract BeaconMock {
    address public deployedAddr;

    function deploy(address impl) external {
        deployedAddr = BeaconDeployer.deploy(impl);
    }

    function changeImplementation(address newImpl) external returns (bool success, bytes memory data) {
        bytes memory newAddr = abi.encode(newImpl);
        (success, data) = deployedAddr.call(newAddr);
    }
}
