/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../interfaces/IMulticall.sol";

abstract contract Multicall is IMulticall {
    function multicall(bytes[] calldata callData) external override returns (bytes[] memory returnData) {
        returnData = new bytes[](callData.length);
        for (uint256 i = 0; i < callData.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(callData[i]);
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (!success) {
                // revert called without a message
                if (result.length < 68) revert();
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            returnData[i] = result;
        }
    }
}
