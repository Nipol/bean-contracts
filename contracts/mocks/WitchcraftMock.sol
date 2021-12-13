/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../library/Witchcraft.sol";
bytes32 constant SHORT_COMMAND_FILL = 0x000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

contract WitchcraftMock {
    using Witchcraft for bytes[];

    function extract(bytes[] memory elements, bytes32 spell) external pure returns (uint256 value) {
        bytes32 indices = bytes32((spell << 40) | SHORT_COMMAND_FILL);
        return elements.extract(indices);
    }

    function toSpell(
        bytes[] memory elements,
        bytes4 selector,
        bytes32 spell
    ) external view returns (bytes memory ret) {
        bytes32 indices = bytes32((spell << 40) | SHORT_COMMAND_FILL);
        ret = elements.toSpell(selector, indices);
    }
}
