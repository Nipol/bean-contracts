/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

// Call Type
uint8 constant FLAG_SP_MASK = 0xc0;
uint8 constant FLAG_SP_DELEGATECALL = 0x00;
uint8 constant FLAG_SP_CALL = 0x40;
uint8 constant FLAG_SP_STATICCALL = 0x80;

// Option Type
uint8 constant FLAG_SP_EXTENSION = 0x20;
uint8 constant FLAG_SP_RETURN = 0x10;

// FILLING the EOF
uint256 constant SHORT_SPELL_FILL = 0x00000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

uint256 constant IDX_VARIABLE_LENGTH = 0x80;
uint256 constant IDX_VALUE_MASK = 0x7f;
uint256 constant IDX_END_OF_ARGS = 0xff;
uint256 constant IDX_USE_STATE = 0xfe;

/**
 * @title Wizadry
 * @author yoonsung.eth
 * @notice Contract가 실행하는 모든 유형의 call type에 대해 미리 정의된 인터페이스를 사용하여 각 실행단계를 더 쉽게 검증 및 구성할 수 있도록 함
 * 미리 정의된 인터페이스는 Spell book으로 정의하며, 각각의 call은 Spell Book 속의 spell을 이용함.
 * 이는 컨트랙트가 각각의 인터페이스를 구현하지 않더라도, Storage영역을 더럽히지 않는 Spell Book을 이용하여 실행 컨텍스트를 일치시킬 수 있다.
 * @dev Spell 명세를 따라야 하며, 해당 라이브러리를 이용할 때 사용되는 Spell Book은 저장영역을 더럽히지 않아야 한다.
 */
abstract contract Wizadry {
    /**
     * @notice
     * @dev Spell Specification
     *
     *  bytes32 map
     *       08      02         14                           40
     *     sig     │ fg │   I/O Mapping  │            spell book address
     *  0x00000000   00   00000000000000   0000000000000000000000000000000000000000
     *  0xffffffff   aa   bbbbbbbbbbbbbb   eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
     *          48   40   32
     *
     *  slot map
     *  0                   1                   2                   3
     *  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
     * ┌───────┬─┬─┬─┬─┬─┬─┬─┬─┬────────────────────────────────────────┐
     * │  sig  │f│ I/O Mapping │          Spell Book Address            │
     * └▲──────┴▲┴▲┴─┴─┴─┴─┴─┴─┴────────────────────────────────────────┘
     *  │       │ │
     *  │       │ │ Input / Output Mapping 1 byte, 8 bit, 0x00000000)
     *  │       │ │ - 각 위치는 사용할 값의 인덱스로 사용되며, 각 값을 어떻게 해석해야 하는지에 대한 정보가 담겨있다.
     *  │       │ │   0     1     2     3     4     5     6     7
     *  │       │ │┌─────┬─────┬─────────────────────────────────┐
     *  │       │ └│ VAR │ VAL │             length              │
     *  │       │  └──▲──┴──▲──┴─────────────────────────────────┘
     *  │       │     │     │
     *  │       │     │     │
     *  │       │     │     │
     *  │       │     │     │
     *  │       │     │     │
     *  │       │     │     └0 bit인 경우, 해당 Index를 매개 변수를 위한 필드로 사용 한다.
     *  │       │     │      1 bit인 경우, 해당 Index를 value로 사용 한다. 해당 필드의 나머지 옵션을 비활성화 하고, 32bytes로 해석함.
     *  │       │     │
     *  │       │     └0 bit인 경우 해당 Index의 parameter를 32bytes 고정으로 해석한다.
     *  │       │      1 bit인 경우 해당 Index의 parameter를 length * 32bytes로 해석하여, 32bytes로 나뉘어야 한다.
     *  │       │
     *  │       │ Flag(1 byte, 8 bit, 0x00000000)
     *  │       │   0    1     2     3     4     5     6     7
     *  │       │┌──────────┬─────┬─────┬─────┬─────┬─────┬─────┐
     *  │       └│  C Type  │ EXT │ TUP │    Future Reserved    │
     *  │        └───▲──────┴──▲──┴──▲──┴─────┴─────┴─────┴─────┘
     *  │            │         │     │
     *  │            │         │     │
     *  │            │         │     │
     *  │            │         │     │┌TUPLE─────────────────────┐
     *  │            │         │     └│ use the return data to I │
     *  │            │         │      └──────────────────────────┘
     *  │            │         │┌EXTENSION─────────────────┐
     *  │            │         └│ I/O for parameter over 7 │
     *  │            │          └──────────────────────────┘
     *  │            └┌Call types──────────────────┐
     *  │             │ 0x0000 │  DELEGATECALL     │
     *  │             ├────────┼───────────────────┤
     *  │             │ 0x0100 │  CALL             │
     *  │             ├────────┼───────────────────┤
     *  │             │ 0x1000 │  STATICCALL       │
     *  │             └────────┴───────────────────┘
     *  │
     *  └ Function Signature for Spell Book. (4 bytes)
     *
     */
    function cast(bytes32[] memory spells, bytes[] memory words) internal {
        bytes32 command;
        uint8 flags;
        bytes32 indices;

        bool success;
        bytes memory outdata;

        for (uint256 i = 0; i < spells.length; i++) {
            command = spells[i];
            // 0x00000000 & 0x11000000 = 0x00000000
            // 0x01000000 & 0x11000000 = 0x01000000
            // 0x10000000 & 0x11000000 = 0x10000000
            // 타입 캐스팅은 마지막에서 잘라서 온다.
            flags = uint8(bytes1(command << 32));

            // only indice
            // 나는 indice의 한 슬롯을 ether로 사용하고 싶다...
            if (flags & FLAG_SP_EXTENSION != 0) {
                indices = spells[i++];
            } else {
                indices = bytes32(uint256(command << 40) | SHORT_SPELL_FILL);
            }

            if (flags & FLAG_SP_MASK == FLAG_SP_DELEGATECALL) {
                (, bytes memory input) = buildInputs(words, bytes4(command), indices);
                (success, outdata) = address(uint160(uint256(command))).delegatecall(input);
            } else if (flags & FLAG_SP_MASK == FLAG_SP_CALL) {
                (uint256 balance, bytes memory input) = buildInputs(words, bytes4(command), indices);
                (success, outdata) = address(uint160(uint256(command))).call{value: balance}(input);
            } else if (flags & FLAG_SP_MASK == FLAG_SP_STATICCALL) {
                (, bytes memory input) = buildInputs(words, bytes4(command), indices);
                (success, outdata) = address(uint160(uint256(command))).staticcall(input);
            } else {
                revert("Invalid calltype");
            }
        }
    }

    function buildInputs(
        bytes[] memory words,
        bytes4 selector,
        bytes32 indices
    ) internal view returns (uint256 balance, bytes memory ret) {
        uint256 count = 0; // Number of bytes in whole ABI encoded message
        uint256 free = 0; // Pointer to first free byte in tail part of message
        bytes memory stateData; // Optionally encode the current state if the call requires it

        uint256 idx;

        // Determine the length of the encoded data
        for (uint256 i = 0; i < 32; i++) {
            idx = uint8(indices[i]);
            if (idx == IDX_END_OF_ARGS) break;

            if (idx & IDX_VARIABLE_LENGTH != 0) {
                if (idx == IDX_USE_STATE) {
                    if (stateData.length == 0) {
                        stateData = abi.encode(words);
                    }
                    count += stateData.length;
                    free += 32;
                } else {
                    // Add the size of the value, rounded up to the next word boundary, plus space for pointer and length
                    uint256 arglen = words[idx & IDX_VALUE_MASK].length;
                    assert(arglen % 32 == 0);
                    count += arglen + 32;
                    free += 32;
                }
            } else {
                assert(words[idx & IDX_VALUE_MASK].length == 32);
                count += 32;
                free += 32;
            }
        }

        // Encode it
        ret = new bytes(count + 4);
        assembly {
            mstore(add(ret, 32), selector)
        }
        count = 0;
        for (uint256 i = 0; i < 32; i++) {
            idx = uint8(indices[i]);
            if (idx == IDX_END_OF_ARGS) break;

            if (idx & IDX_VARIABLE_LENGTH != 0) {
                if (idx == IDX_USE_STATE) {
                    assembly {
                        mstore(add(add(ret, 36), count), free)
                    }
                    memcpy(stateData, 32, ret, free + 4, stateData.length - 32);
                    free += stateData.length - 32;
                    count += 32;
                } else {
                    uint256 arglen = words[idx & IDX_VALUE_MASK].length;

                    // Variable length data; put a pointer in the slot and write the data at the end
                    assembly {
                        mstore(add(add(ret, 36), count), free)
                    }
                    memcpy(words[idx & IDX_VALUE_MASK], 0, ret, free + 4, arglen);
                    free += arglen;
                    count += 32;
                }
            } else {
                // Fixed length data; write it directly
                bytes memory statevar = words[idx & IDX_VALUE_MASK];
                assembly {
                    mstore(add(add(ret, 36), count), mload(add(statevar, 32)))
                }
                count += 32;
            }
        }
    }

    function memcpy(
        bytes memory src,
        uint256 srcidx,
        bytes memory dest,
        uint256 destidx,
        uint256 len
    ) internal view {
        assembly {
            pop(staticcall(gas(), 4, add(add(src, 32), srcidx), len, add(add(dest, 32), destidx), len))
        }
    }
}
