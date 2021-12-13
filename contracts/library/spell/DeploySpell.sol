/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

contract DeploySpell {
    function cast(uint256 value, bytes memory byteCode) external returns (address deployed) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            deployed := create(value, add(byteCode, 0x20), mload(byteCode))
            if iszero(extcodesize(deployed)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function cast(
        uint256 value,
        bytes memory byteCode,
        bytes32 salt
    ) external returns (address deployed) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            deployed := create2(value, add(byteCode, 0x20), mload(byteCode), salt)
            if iszero(extcodesize(deployed)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}
