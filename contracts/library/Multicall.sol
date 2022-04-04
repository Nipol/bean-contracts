/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../interfaces/IMulticall.sol";

/**
 * @title Multicall
 * @author yoonsung.eth
 * @notice This library allows to execute functions specified in the contract in order.
 */
abstract contract Multicall is IMulticall {
    /**
     * @notice Put the calldata to be called in order and execute it.
     * @dev there is an operation that fails while running in order, all operations will be reverted.
     * @param callData      bytes calldata to self.
     * @return returnData   data returned from the called function.
     */
    function multicall(bytes[] calldata callData) external returns (bytes[] memory returnData) {
        uint256 length = callData.length;
        returnData = new bytes[](length);
        for (uint256 i; i != length; ) {
            (bool success, bytes memory result) = address(this).delegatecall(callData[i]);
            if (!success) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    revert(add(32, result), mload(result))
                }
            }

            returnData[i] = result;

            unchecked {
                ++i;
            }
        }
    }
}
