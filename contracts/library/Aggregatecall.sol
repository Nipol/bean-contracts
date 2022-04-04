/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../interfaces/IAggregatecall.sol";

/**
 * @title Aggregatecall
 * @author yoonsung.eth
 * @notice The contract using this library is set the caller to this contract and calls are execute in order.
 */
abstract contract Aggregatecall is IAggregatecall {
    /**
     * @notice Put the target address and the data to be called in order and execute it.
     * @dev there is an operation that fails while running in order, all operations will be reverted.
     * @param calls         object with the address and data.
     * @return returnData   data returned from the called function.
     */
    function aggregate(Call[] calldata calls) public returns (bytes[] memory returnData) {
        uint256 length = calls.length;
        returnData = new bytes[](length);
        Call calldata calli;
        for (uint256 i; i != length; ) {
            calli = calls[i];
            (bool success, bytes memory result) = calli.target.call(calli.data);
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
