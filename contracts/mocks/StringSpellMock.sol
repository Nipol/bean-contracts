/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

contract StringSpellMock {
    function strlen(string calldata x) external pure returns (uint256) {
        return bytes(x).length;
    }

    function strcat(string calldata a, string calldata b) external pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
}
