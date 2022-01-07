/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../../interfaces/IERC20.sol";

contract ERC20Spell {
    function balanceOf(IERC20 ERC20, address target) external view returns (uint256 value) {
        value = ERC20.balanceOf(target);
    }

    function allowance(
        IERC20 ERC20,
        address owner,
        address spender
    ) external view returns (uint256 value) {
        value = ERC20.allowance(owner, spender);
    }

    function safeTransfer(
        IERC20 ERC20,
        address to,
        uint256 value
    ) external returns (bool success) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freePointer := mload(0x40)
            mstore(freePointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freePointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freePointer, 36), value)
            success := call(gas(), ERC20, 0, freePointer, 68, 0, 0)
        }
        success = callProofer(success);
    }

    function safeTransferFrom(
        IERC20 ERC20,
        address from,
        address to,
        uint256 value
    ) external returns (bool success) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freePointer := mload(0x40)
            mstore(freePointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freePointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freePointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freePointer, 68), value)
            success := call(gas(), ERC20, 0, freePointer, 100, 0, 0)
        }
        success = callProofer(success);
    }

    function safeApprove(
        IERC20 ERC20,
        address spender,
        uint256 value
    ) external returns (bool success) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freePointer := mload(0x40)
            mstore(freePointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freePointer, 4), and(spender, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(freePointer, 36), value)
            success := call(gas(), ERC20, 0, freePointer, 68, 0, 0)
        }

        success = callProofer(success);
    }

    function callProofer(bool callStatus) private pure returns (bool success) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let returnDataSize := returndatasize()

            if iszero(callStatus) {
                returndatacopy(0, 0, returnDataSize)
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                returndatacopy(0, 0, returnDataSize)
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                success := 1
            }
            default {
                success := 0
            }
        }
    }
}
