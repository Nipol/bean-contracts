/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../interfaces/IAggregatecall.sol";

/**
 * @title Aggregatecall
 * @author yoonsung.eth
 * @notice 컨트랙트가 가지고 있는 트랜잭션을 순서대로 실행시킬 수 있음.
 */
abstract contract Aggregatecall is IAggregatecall {
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
