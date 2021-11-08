/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

/**
 * @title Caster
 * @author yoonsung.eth
 * @notice Contract가 할 수 있는 모든 호출을 담당함.
 *
 */

uint8 constant FLAG_CT_DELEGATECALL = 0x00;
uint8 constant FLAG_CT_CALL = 0x01;
uint8 constant FLAG_CT_STATICCALL = 0x02;
uint8 constant FLAG_CT_VALUECALL = 0x03;
uint8 constant FLAG_CT_MASK = 0x03;
uint8 constant FLAG_EXTENDED_COMMAND = 0x80;
uint8 constant FLAG_TUPLE_RETURN = 0x40;

abstract contract Caster {
    /**
     * @notice
     * @dev
     * - spell Specification
     *  0                   1                   2                   3
     *  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
     * ┌───────┬─┬─────────────┬────────────────────────────────────────┐
     * │  sig  │f│             │          Spell Book Address            │
     * └▲──────┴▲┴─────────────┴────────────────────────────────────────┘
     *  │       │
     *  │       │
     *  │       │
     *  │       │
     *  │       │
     *  │       │
     *  │       │ Flag
     *  │       │ 0   1   2   3   4   5   6   7
     *  │       │┌──────┬──────────────────────┐
     *  │       └│ type │                      │
     *  │        └──────┴──────────────────────┘
     *  │
     *  └ Function Signature from Spell Book.
     */
    function cast(
        bytes32[] memory spells,
        uint96[] balances,
        bytes32[] memory parameter
    ) internal {
        bytes32 command;
        uint8 flags;

        for (uint256 i = 0; i < spells.length; i++) {
            command = spells[i];
            flags = uint8(bytes1(command << 32));

            // mutated from previous returned data.
            // if (flags & FLAG_EXTENDED_COMMAND != 0) {
            //     indices = commands[i++];
            // } else {
            //     indices = bytes32(uint256(command << 40) | SHORT_COMMAND_FILL);
            // }

            if (flags & FLAG_CT_MASK == FLAG_CT_DELEGATECALL) {
                address(uint160(uint256(command))).delegatecall(abi.encodeWithSelector(bytes4(command), calls[i]));
            } else if (flags & FLAG_CT_MASK == FLAG_CT_CALL) {
                address(uint160(uint256(command))).call(abi.encodeWithSelector(bytes4(command), calls[i]));
            } else if (flags & FLAG_CT_MASK == FLAG_CT_STATICCALL) {
                address(uint160(uint256(command))).staticcall(abi.encodeWithSelector(bytes4(command), calls[i]));
            } else if (flags & FLAG_CT_MASK == FLAG_CT_VALUECALL) {
                address(uint160(uint256(command))).call{value: balances[i]}(
                    abi.encodeWithSelector(bytes4(command), calls[i])
                );
            }
        }
    }

    function cast(
        address[] calldata spells,
        uint256[] balances,
        bytes[] calldata calls
    ) internal returns (bytes[] memory results) {
        require(spells.length == calls.length);
        bool success;
        results = new bytes[](spells.length);
        for (uint256 i = 0; i < spells.length; i++) {
            (address spell, bytes memory call) = (spells[i], calls[i]);
            // TODO: returned data, using next call.
            (success, results[i]) = spell.delegatecall(call);
            assert(success);
        }
    }
}
