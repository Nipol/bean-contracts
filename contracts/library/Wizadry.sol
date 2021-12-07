/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Witchcraft.sol";

// Call Type
uint8 constant FLAG_SP_MASK = 0xc0;
uint8 constant FLAG_SP_DELEGATECALL = 0x00;
uint8 constant FLAG_SP_CALL = 0x40;
uint8 constant FLAG_SP_CALL_VALUE = 0x80;
uint8 constant FLAG_SP_STATICCALL = 0xc0;

// Option Type
uint8 constant FLAG_SP_EXTENSION = 0x20;
uint8 constant FLAG_SP_RETURN = 0x10;
uint256 constant IDX_END_OF_ARGS = 0xff;
// FILLING the EOF
uint256 constant SHORT_SPELL_FILL = 0x00000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

/**
 * @title Wizadry
 * @author yoonsung.eth
 * @notice Contract가 실행하는 모든 유형의 call type에 대해 미리 정의된 인터페이스를 사용하여 각 실행단계를 더 쉽게 검증 및 구성할 수 있도록 함
 * 미리 정의된 인터페이스는 Spell book으로 정의하며, 각각의 call은 Spell Book 속의 spell을 이용함.
 * 이는 컨트랙트가 각각의 인터페이스를 구현하지 않더라도, Storage영역을 더럽히지 않는 Spell Book을 이용하여 실행 컨텍스트를 일치시킬 수 있다.
 * @dev Spell 명세를 따라야 하며, 해당 라이브러리를 이용할 때 사용되는 Spell Book은 저장영역을 더럽히지 않아야 한다.
 */
abstract contract Wizadry {
    using Witchcraft for bytes[];

    /**
     * @notice
     * @dev Spell Specification
     *  slot map
     *  0                   1                   2                   3
     *  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
     * ┌───────┬─┬─┬─┬─┬─┬─┬─┬─┬────────────────────────────────────────┐
     * │  sig  │f│ I/O Mapping │          Spell Book Address            │
     * └▲──────┴▲┴┬┴─┴─┴─┴─┴─┴┬┴────────────────────────────────────────┘
     *  │       │ └▲──────────┘
     *  │       │  │
     *  │       │  └Library/Witchcraft.sol 에서 명세 확인
     *  │       │
     *  │       │ Flag(1 byte, 8 bit, 0x00000000)
     *  │       │ - 해당 Spell을 어떻게 해석할지에 대한 사전 정보를 담고 있는 슬롯
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
     *  │            └┌Call types──────────────────┐
     *  │             │ 0x0000 │  DELEGATECALL     │
     *  │             ├────────┼───────────────────┤
     *  │             │ 0x0100 │  CALL             │
     *  │             ├────────┼───────────────────┤
     *  │             │ 0x1000 │  CALL with Value  │
     *  │             ├────────┼───────────────────┤
     *  │             │ 0x1100 │  STATICCALL       │
     *  │             └────────┴───────────────────┘
     *  │
     *  └ Function Signature for Spell Book. (4 bytes)
     */
    function _cast(bytes32[] memory spells, bytes[] memory elements) internal returns (bytes[] memory) {
        bytes32 command;
        uint8 flags;
        bytes32 indices;

        bool success;
        bytes memory outdata;

        for (uint256 i = 0; i < spells.length; i++) {
            command = spells[i];
            flags = uint8(bytes1(command << 32));

            if (flags & FLAG_SP_EXTENSION != 0) {
                indices = spells[i++];
            } else {
                indices = bytes32(uint256(command << 40) | SHORT_SPELL_FILL);
            }

            if (flags & FLAG_SP_MASK == FLAG_SP_DELEGATECALL) {
                (success, outdata) = address(uint160(uint256(command))).delegatecall(
                    elements.toSpell(bytes4(command), indices)
                );
            } else if (flags & FLAG_SP_MASK == FLAG_SP_CALL) {
                console.logUint(i);
                (success, outdata) = address(uint160(uint256(command))).call(
                    elements.toSpell(bytes4(command), indices)
                );
            } else if (flags & FLAG_SP_MASK == FLAG_SP_CALL_VALUE) {
                uint256 balance = elements.extract(indices);
                (success, outdata) = address(uint160(uint256(command))).call{value: balance}(
                    elements.toSpell(bytes4(command), bytes32(uint256(indices << 8) | IDX_END_OF_ARGS))
                );
            } else if (flags & FLAG_SP_MASK == FLAG_SP_STATICCALL) {
                (success, outdata) = address(uint160(uint256(command))).staticcall(
                    elements.toSpell(bytes4(command), indices)
                );
            } else {
                revert("Invalid calltype");
            }

            assert(success);

            if (flags & FLAG_SP_RETURN != 0) {
                elements.writeTuple(bytes1(command << 88), outdata);
            } else {
                // console.logBytes1(bytes1(command << 88));
                elements = elements.writeOutputs(bytes1(command << 88), outdata);
            }
        }
        return elements;
    }
}
