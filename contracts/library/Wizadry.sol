/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "./Witchcraft.sol";

// Call Type
uint8 constant FLAG_CT_MASK = 0xc0;
uint8 constant FLAG_CT_DELEGATECALL = 0x00;
uint8 constant FLAG_CT_CALL = 0x40;
uint8 constant FLAG_CT_CALL_VALUE = 0x80;
uint8 constant FLAG_CT_STATICCALL = 0xc0;
// Option Type
uint8 constant FLAG_EXTENSION = 0x20;
uint8 constant FLAG_TUPLE = 0x10;
// FILLING the EOF
uint256 constant SHORT_SPELL_FILL = 0x00000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

/**
 * @title Wizadry
 * @author yoonsung.eth
 * @notice Contract가 실행하는 모든 유형의 call type에 대해 미리 정의된 인터페이스를 사용하여 각 실행단계를 더 쉽게 검증 및 구성할 수 있도록 함
 * 미리 정의된 인터페이스는 Spell book으로 정의하며, 각각의 call은 Spell Book 속의 spell을 이용함.
 * 이는 컨트랙트가 각각의 인터페이스를 구현하지 않더라도, Storage영역을 더럽히지 않는 Spell Book을 이용하여 실행 컨텍스트를 일치시킬 수 있다.
 * @dev 해당 라이브러리는 Spell, Elements 명세를 따라야 하며, Spell Book은 Storage 영역을 더럽히지 않아야 한다.
 */
abstract contract Wizadry {
    using Witchcraft for bytes[];

    address immutable self;

    modifier ensureOnCall() {
        require(address(this) == self);
        _;
    }

    constructor() {
        self = address(this);
    }

    /**
     * @notice
     * @dev Specification
     * Spell
     *  slot map
     *  0                   1                   2                   3
     *  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
     * ┌───────┬─┬─┬─┬─┬─┬─┬─┬─┬────────────────────────────────────────┐
     * │  sig  │f│ I/O idx Map │          Spell Book Address            │
     * └▲──────┴▲┴┬┴─┴─┴─┴─┴─┴┬┴────────────────────────────────────────┘
     *  │       │ └▲──────────┘
     *  │       │  │
     *  │       │  └Input / Output index Mapping.
     *  │       │   - using Last index for output data position.
     *  │       │
     *  │       │ Flag(1 byte, 8 bit, 0x00000000)
     *  │       │ - how to translate this spell using stored pre-information.
     *  │       │   0    1     2     3     4     5     6     7
     *  │       │┌──────────┬─────┬─────┬─────┬─────┬─────┬─────┐
     *  │       └│  C Type  │ EXT │ TUP │    Future Reserved    │
     *  │        └───▲──────┴──▲──┴──▲──┴─────┴─────┴─────┴─────┘
     *  │            │         │     │
     *  │            │         │     │┌TUPLE─────────────────────┐
     *  │            │         │     └│ use the return data to I │
     *  │            │         │      └──────────────────────────┘
     *  │            │         │
     *  │            │         │┌EXTENSION─────────────────┐
     *  │            │         └│ I/O for parameter over 7 │
     *  │            │          └──────────────────────────┘
     *  │            │
     *  │            └┌Call types───────────────┐
     *  │             │ 0b00 │  DELEGATECALL     │
     *  │             ├──────┼───────────────────┤
     *  │             │ 0b01 │  CALL             │
     *  │             ├──────┼───────────────────┤
     *  │             │ 0b10 │  CALL with Value  │
     *  │             ├──────┼───────────────────┤
     *  │             │ 0b11 │  STATICCALL       │
     *  │             └──────┴───────────────────┘
     *  │
     *  └ Function Signature for Spell Book. (4 bytes)
     *
     * Input / Output index Mapping
     *  slot map
     *    0     1     2     3     4     5     6     7
     * ┌──────────┬───────────────────────────────────┐
     * │ El types │  Pos                              │
     * └────▲─────┴─▲─────────────────────────────────┘
     *      │       │
     *      │       └Basically range of 0~63, this value for elements index.
     *      │        if mapping value is 0xFF stop translate element.
     *      │
     *      └┌Call types────────────────┐
     *       │ 0b00 │  STATIC INDEX     │
     *       ├──────┼───────────────────┤
     *       │ 0b01 │  PACK INDEX       │
     *       ├──────┼───────────────────┤
     *       │ 0b10 │  DYNAMIC INDEX    │
     *       ├──────┼───────────────────┤
     *       │ 0b11 │  Entire ELEMENTS  │
     *       └──────┴───────────────────┘
     */
    function cast(bytes32[] calldata spells, bytes[] memory elements) internal ensureOnCall returns (bytes[] memory) {
        bytes32 command;
        uint8 flags;
        bytes32 indices;
        bytes1 outputPos;

        bool success;
        bytes memory outdata;

        for (uint256 i = 0; i < spells.length; i++) {
            command = spells[i];
            flags = uint8(bytes1(command << 32));

            if (flags & FLAG_EXTENSION != 0) {
                indices = spells[++i];
                outputPos = bytes1(indices << 248);
            } else {
                indices = bytes32(uint256(command << 40) | SHORT_SPELL_FILL);
                outputPos = bytes1(command << 88);
            }

            if (flags & FLAG_CT_MASK == FLAG_CT_DELEGATECALL) {
                (success, outdata) = address(uint160(uint256(command))).delegatecall(
                    elements.toSpell(bytes4(command), indices)
                );
            } else if (flags & FLAG_CT_MASK == FLAG_CT_CALL) {
                (success, outdata) = address(uint160(uint256(command))).call(
                    elements.toSpell(bytes4(command), indices)
                );
            } else if (flags & FLAG_CT_MASK == FLAG_CT_CALL_VALUE) {
                uint256 balance = elements.extract(indices);
                (success, outdata) = address(uint160(uint256(command))).call{value: balance}(
                    elements.toSpell(bytes4(command), bytes32(uint256(indices << 8) | 0xff))
                );
            } else if (flags & FLAG_CT_MASK == FLAG_CT_STATICCALL) {
                (success, outdata) = address(uint160(uint256(command))).staticcall(
                    elements.toSpell(bytes4(command), indices)
                );
            } else {
                revert("Invalid calltype");
            }

            if (!success) {
                // pass along failure message from calls and revert.
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }

            if (flags & FLAG_TUPLE != 0) {
                elements.writeTuple(outputPos, outdata);
            } else {
                elements = elements.writeOutputs(outputPos, outdata);
            }
        }
        return elements;
    }
}
