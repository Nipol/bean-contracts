/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../interfaces/IMulticall.sol";

/**
 * @title Multicall
 * @author yoonsung.eth
 * @notice 컨트랙트가 가지고 있는 트랜잭션을 순서대로 실행시킬 수 있음.
 */
abstract contract Multicall is IMulticall {
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
