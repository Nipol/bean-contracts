/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../library/Multicall.sol";

contract MulticallMock is Multicall {
    uint256 public stage = 0;

    function increase() external {
        stage++;
    }

    function decrease() external {
        stage--;
    }

    function increaseWithLongMessage() external returns(bytes memory message) {
        stage++;
        message = new bytes(65500);
    }

    function decreaseWithLongMessage() external returns(bytes memory message) {
        stage++;
        message = new bytes(65500);
    }
}