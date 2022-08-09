/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../library/PermissionTable.sol";

contract PermissionMock is PermissionTable {
    function Grant(
        address envoy,
        bytes4 sig,
        bytes3 permission
    ) external {
        grant(envoy, sig, permission);
    }
}

contract PermissionTest is Test {
    PermissionMock p;

    function setUp() public {
        p = new PermissionMock();

        vm.etch(address(11), abi.encode(0x6080604052348015610010));
        p.Grant(address(11), 0xDEADBEEF, 0x010000);

        vm.etch(address(12), abi.encode(0x6080604052348015610010));
        p.Grant(address(12), 0xDEADBEEF, 0x000200);

        p.Grant(address(13), 0xDEADBEEF, 0x000003);
    }

    function testGrantToUser() public {
        p.Grant(address(11), 0xBEEFBEEF, 0x000003);

        assertTrue(p.isUser(address(11), 0xBEEFBEEF));
        assertTrue(!p.isGroup(address(11), 0xBEEFBEEF));
        assertTrue(!p.isRoot(address(11), 0xBEEFBEEF));
    }

    function testGrantToGroup() public {
        p.Grant(address(11), 0xBEEFBEEF, 0x000100);

        assertTrue(!p.isUser(address(11), 0xBEEFBEEF));
        assertTrue(p.isGroup(address(11), 0xBEEFBEEF));
        assertTrue(!p.isRoot(address(11), 0xBEEFBEEF));
    }

    function testGrantToRoot() public {
        p.Grant(address(11), 0xBEEFBEEF, 0x010000);

        assertTrue(!p.isUser(address(11), 0xBEEFBEEF));
        assertTrue(!p.isGroup(address(11), 0xBEEFBEEF));
        assertTrue(p.isRoot(address(11), 0xBEEFBEEF));
    }

    function testCanCallWithPermissionedRoot() public {
        assertTrue(p.canCall(address(11), 0xDEADBEEF));
        assertTrue(!p.canCall(address(11), 0xDEADBEEF, 0x02));
        assertTrue(!p.canCall(address(11), 0xDEADBEEF, 0x02, 0, 0));
    }

    function testCanCallWithOutPermissionedContractRoot() public {
        assertTrue(!p.canCall(address(11), 0xC0ffee00));
        assertTrue(!p.canCall(address(11), 0xC0ffee00, 0x02));
        assertTrue(!p.canCall(address(11), 0xC0ffee00, 0x02, 0, 0));
    }

    function testCanCallWithPermissionedGroup() public {
        emit log_named_uint("envoy code length", address(12).code.length);
        assertTrue(p.canCall(address(12), 0xDEADBEEF));
        assertTrue(!p.canCall(address(12), 0xDEADBEEF, 0x03));
        assertTrue(!p.canCall(address(12), 0xDEADBEEF, 0, 0x03, 0));
    }

    function testCanCallWithOutPermissionedGroup() public {
        assertTrue(!p.canCall(address(12), 0xC0ffee00));
    }

    function testCanCallWithPermissionedUser() public {
        assertTrue(p.canCall(address(13), 0xDEADBEEF));
        assertTrue(!p.canCall(address(13), 0xDEADBEEF, 0x04));
        assertTrue(!p.canCall(address(13), 0xDEADBEEF, 0, 0, 0x04));
    }

    function testIsAuthenticatedWithPermissionedRoot() public {
        assertEq(uint256(p.isAuthenticated(address(11), 0xDEADBEEF)), 1);
        assertEq(uint256(p.isAuthenticated(address(11), 0xDEADBEEF, 0x02)), 0);
        assertEq(uint256(p.isAuthenticated(address(11), 0xDEADBEEF, 0x02, 0, 0)), 0);
    }

    function testIsAuthenticatedWithPermissionedContractRoot() public {
        assertEq(uint256(p.isAuthenticated(address(11), 0xDEADBEEF)), 1);
        assertEq(uint256(p.isAuthenticated(address(11), 0xDEADBEEF, 0x02)), 0);
        assertEq(uint256(p.isAuthenticated(address(11), 0xDEADBEEF, 0x02, 0, 0)), 0);
    }

    function testIsAuthenticatedWithOutPermissionedContractRoot() public {
        assertEq(uint256(p.isAuthenticated(address(11), 0xC0ffee00)), 0);
        assertEq(uint256(p.isAuthenticated(address(11), 0xC0ffee00, 0x02)), 0);
        assertEq(uint256(p.isAuthenticated(address(11), 0xC0ffee00, 0x02, 0, 0)), 0);
    }

    function testIsAuthenticatedWithPermissionedGroup() public {
        assertEq(uint256(p.isAuthenticated(address(12), 0xDEADBEEF)), 2);
        assertEq(uint256(p.isAuthenticated(address(12), 0xDEADBEEF, 0x03)), 0);
        assertEq(uint256(p.isAuthenticated(address(12), 0xDEADBEEF, 0, 0x03, 0)), 0);
    }

    function testIsAuthenticatedWithOutPermissionedGroup() public {
        assertEq(uint256(p.isAuthenticated(address(12), 0xC0ffee00)), 0);
    }

    function testIsAuthenticatedWithPermissionedUser() public {
        assertEq(uint256(p.isAuthenticated(address(13), 0xDEADBEEF)), 3);
        assertEq(uint256(p.isAuthenticated(address(13), 0xDEADBEEF, 0x04)), 0);
        assertEq(uint256(p.isAuthenticated(address(13), 0xDEADBEEF, 0, 0, 0x04)), 0);
    }
}
