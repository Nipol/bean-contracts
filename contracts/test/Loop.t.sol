/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "ds-test/test.sol";

contract LoopTest is DSTest {
    function testLoop1() public {
        uint256[] memory arr = new uint256[](256);
        for (uint256 i = 0; i < arr.length; i++) {
            arr[i] = i;
        }
        assertEq(arr[255], 255);
    }

    function testLoop2() public {
        uint256[] memory arr = new uint256[](256);
        uint256 length = arr.length;
        for (uint256 i = 0; i < length; i++) {
            arr[i] = i;
        }
        assertEq(arr[255], 255);
    }

    function testLoop3() public {
        uint256[] memory arr = new uint256[](256);
        uint256 length = arr.length;
        for (uint256 i; i < length; i++) {
            arr[i] = i;
        }
        assertEq(arr[255], 255);
    }

    function testLoop4() public {
        uint256[] memory arr = new uint256[](256);
        uint256 length = arr.length;
        for (uint256 i; i < length; ++i) {
            arr[i] = i;
        }
        assertEq(arr[255], 255);
    }

    function testLoop5() public {
        uint256[] memory arr = new uint256[](256);
        uint256 length = arr.length;
        for (uint256 i; i < length; ) {
            arr[i] = i;
            unchecked {
                i++;
            }
        }
        assertEq(arr[255], 255);
    }

    function testLoop6() public {
        uint256[] memory arr = new uint256[](256);
        uint256 length = arr.length;
        for (uint256 i; i < length; ) {
            arr[i] = i;
            unchecked {
                ++i;
            }
        }
        assertEq(arr[255], 255);
    }

    function testLoop7() public {
        uint256[] memory arr = new uint256[](256);
        uint256 length = arr.length;
        for (uint256 i; i != length; ) {
            arr[i] = i;
            unchecked {
                i++;
            }
        }
        assertEq(arr[255], 255);
    }

    function testLoop8() public {
        uint256[] memory arr = new uint256[](256);
        uint256 length = arr.length;
        for (uint256 i; i != length; ) {
            arr[i] = i;
            unchecked {
                ++i;
            }
        }
        assertEq(arr[255], 255);
    }
}
