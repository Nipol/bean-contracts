/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

contract MathSpell {
    function add(uint256 a, uint256 b) external pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) external pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) external pure returns (uint256) {
        return a * b;
    }

    function sum(uint256[] calldata values) external pure returns (uint256 ret) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let len := mload(values.length)
            let data := add(values.offset, 0x20)
            for {
                let end := add(data, mul(len, 0x20))
            } lt(data, end) {
                data := add(data, 0x20)
            } {
                ret := add(ret, mload(data))
            }
        }
    }
}
