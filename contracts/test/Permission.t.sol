/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "../library/PermissionTable.sol";

interface CheatCodes {
    function etch(address who, bytes calldata code) external;
}

contract PermissionMock is PermissionTable {
    function Grant(
        address envoy,
        bytes4 sig,
        bytes3 permission
    ) external {
        grant(envoy, sig, permission);
    }
}

contract PermissionTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    PermissionMock p;

    function setUp() public {
        p = new PermissionMock();

        cheats.etch(address(1), abi.encode(0x0001));
        p.Grant(address(1), 0xDEADBEEF, 0x010000);

        cheats.etch(address(2), abi.encode(0x0001));
        p.Grant(address(2), 0xDEADBEEF, 0x000200);

        p.Grant(address(3), 0xDEADBEEF, 0x000003);
    }

    function testGrantToUser() public {
        p.Grant(address(1), 0xBEEFBEEF, 0x000003);

        assertTrue(p.isUser(address(1), 0xBEEFBEEF));
        assertTrue(!p.isGroup(address(1), 0xBEEFBEEF));
        assertTrue(!p.isRoot(address(1), 0xBEEFBEEF));
    }

    function testGrantToGroup() public {
        p.Grant(address(1), 0xBEEFBEEF, 0x000100);

        assertTrue(!p.isUser(address(1), 0xBEEFBEEF));
        assertTrue(p.isGroup(address(1), 0xBEEFBEEF));
        assertTrue(!p.isRoot(address(1), 0xBEEFBEEF));
    }

    function testGrantToRoot() public {
        p.Grant(address(1), 0xBEEFBEEF, 0x010000);

        assertTrue(!p.isUser(address(1), 0xBEEFBEEF));
        assertTrue(!p.isGroup(address(1), 0xBEEFBEEF));
        assertTrue(p.isRoot(address(1), 0xBEEFBEEF));
    }

    function testCanCallWithPermissionedRoot() public {
        assertTrue(p.canCall(address(1), 0xDEADBEEF));
        assertTrue(!p.canCall(address(1), 0xDEADBEEF, 0x02));
        assertTrue(!p.canCall(address(1), 0xDEADBEEF, 0x02, 0, 0));
    }

    function testCanCallWithOutPermissionedContractRoot() public {
        assertTrue(!p.canCall(address(1), 0xC0ffee00));
        assertTrue(!p.canCall(address(1), 0xC0ffee00, 0x02));
        assertTrue(!p.canCall(address(1), 0xC0ffee00, 0x02, 0, 0));
    }

    function testCanCallWithPermissionedGroup() public {
        assertTrue(p.canCall(address(2), 0xDEADBEEF));
        assertTrue(!p.canCall(address(2), 0xDEADBEEF, 0x03));
        assertTrue(!p.canCall(address(2), 0xDEADBEEF, 0, 0x03, 0));
    }

    function testCanCallWithOutPermissionedGroup() public {
        assertTrue(!p.canCall(address(2), 0xC0ffee00));
    }

    function testCanCallWithPermissionedUser() public {
        assertTrue(p.canCall(address(3), 0xDEADBEEF));
        assertTrue(!p.canCall(address(3), 0xDEADBEEF, 0x04));
        assertTrue(!p.canCall(address(3), 0xDEADBEEF, 0, 0, 0x04));
    }

    function testIsAuthenticatedWithPermissionedRoot() public {
        assertEq(uint256(p.isAuthenticated(address(1), 0xDEADBEEF)), 1);
        assertEq(uint256(p.isAuthenticated(address(1), 0xDEADBEEF, 0x02)), 0);
        assertEq(uint256(p.isAuthenticated(address(1), 0xDEADBEEF, 0x02, 0, 0)), 0);
    }

    function testIsAuthenticatedWithPermissionedContractRoot() public {
        assertEq(uint256(p.isAuthenticated(address(1), 0xDEADBEEF)), 1);
        assertEq(uint256(p.isAuthenticated(address(1), 0xDEADBEEF, 0x02)), 0);
        assertEq(uint256(p.isAuthenticated(address(1), 0xDEADBEEF, 0x02, 0, 0)), 0);
    }

    function testIsAuthenticatedWithOutPermissionedContractRoot() public {
        assertEq(uint256(p.isAuthenticated(address(1), 0xC0ffee00)), 0);
        assertEq(uint256(p.isAuthenticated(address(1), 0xC0ffee00, 0x02)), 0);
        assertEq(uint256(p.isAuthenticated(address(1), 0xC0ffee00, 0x02, 0, 0)), 0);
    }

    function testIsAuthenticatedWithPermissionedGroup() public {
        assertEq(uint256(p.isAuthenticated(address(2), 0xDEADBEEF)), 2);
        assertEq(uint256(p.isAuthenticated(address(2), 0xDEADBEEF, 0x03)), 0);
        assertEq(uint256(p.isAuthenticated(address(2), 0xDEADBEEF, 0, 0x03, 0)), 0);
    }

    function testIsAuthenticatedWithOutPermissionedGroup() public {
        assertEq(uint256(p.isAuthenticated(address(2), 0xC0ffee00)), 0);
    }

    function testIsAuthenticatedWithPermissionedUser() public {
        assertEq(uint256(p.isAuthenticated(address(3), 0xDEADBEEF)), 3);
        assertEq(uint256(p.isAuthenticated(address(3), 0xDEADBEEF, 0x04)), 0);
        assertEq(uint256(p.isAuthenticated(address(3), 0xDEADBEEF, 0, 0, 0x04)), 0);
    }
}
