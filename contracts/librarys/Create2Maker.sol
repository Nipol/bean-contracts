/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

contract Create2Maker {
    constructor(address template, bytes memory initializationCalldata)
        payable
    {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = template.delegatecall(initializationCalldata);
        if (!success) {
            // pass along failure message from delegatecall and revert.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // place eip-1167 runtime code in memory.
        bytes memory runtimeCode =
            abi.encodePacked(
                bytes10(0x363d3d373d3d3d363d73),
                template,
                bytes15(0x5af43d82803e903d91602b57fd5bf3)
            );

        // return eip-1167 code to write it to spawned contract runtime.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            return(add(0x20, runtimeCode), 45) // eip-1167 runtime code, length
        }
    }
}
