/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

/**
 * @title PermissionTable
 * @author yoonsung.eth
 * @notice 컨트랙트에 대해 권리를 가지는 주체를 지정하고, 그 주체가 컨트랙트의 제한된 영역에 접근할 수 있는 인터페이스.
 * Root, Group, User에 따라 각각 256개의 권한을 지정해줄 수 있습니다.
 * @dev permission table은 0x00_00_00 으로 이뤄지며, 각각 Root, Group, User의 권한 레벨을 나타냅니다.
 * Root권한이 부여되어 있다면, 이것은 최대 권한이며, 다른 권한 설정을 무시하고 우선 평가됩니다.
 * 이 외의 주소에 대해서 주소에 코드가 있다면, Group으로 평가되어야 하고, 코드가 없다면 User로 평가되어야 합니다.
 */
abstract contract PermissionTable {
    enum Auth {
        UNKNOWN,
        ROOT,
        GROUP,
        USER
    }

    mapping(address => mapping(bytes4 => bytes32)) public table;

    function grant(
        address envoy,
        bytes4 sig,
        bytes3 permission
    ) internal {
        table[envoy][sig] = permission;
    }

    function canCall(address envoy, bytes4 sig) public view returns (bool) {
        bytes32 pt = table[envoy][sig];

        if (bytes1(pt) != 0) return true;
        else if (envoy.code.length != 0) {
            if (bytes1(pt << 8) != 0) return true;
        } else if (bytes1(pt << 16) != 0) return true;
        return false;
    }

    function canCall(
        address envoy,
        bytes4 sig,
        uint8 req
    ) public view returns (bool) {
        bytes32 pt = table[envoy][sig];

        if (uint8(bytes1(pt)) > req) return true;
        else if (envoy.code.length != 0) {
            if (uint8(bytes1(pt << 8)) > req) return true;
        } else if (uint8(bytes1(pt << 16)) > req) return true;
        return false;
    }

    function canCall(
        address envoy,
        bytes4 sig,
        uint8 rootReq,
        uint8 groupReq,
        uint8 userReq
    ) public view returns (bool) {
        bytes32 pt = table[envoy][sig];

        if (uint8(bytes1(pt)) > rootReq) return true;
        else if (envoy.code.length != 0) {
            if (uint8(bytes1(pt << 8)) > groupReq) return true;
        } else if (uint8(bytes1(pt << 16)) > userReq) return true;
        return false;
    }

    function isAuthenticated(address envoy, bytes4 sig) public view returns (Auth) {
        bytes32 pt = table[envoy][sig];

        if (bytes1(pt) != 0) return Auth.ROOT;
        else if (envoy.code.length != 0) {
            if (bytes1(pt << 8) != 0) return Auth.GROUP;
        } else if (bytes1(pt << 16) != 0) return Auth.USER;
        return Auth.UNKNOWN;
    }

    function isAuthenticated(
        address envoy,
        bytes4 sig,
        uint8 req
    ) public view returns (Auth) {
        bytes32 pt = table[envoy][sig];

        if (uint8(bytes1(pt)) > req) return Auth.ROOT;
        else if (envoy.code.length != 0) {
            if (uint8(bytes1(pt << 8)) > req) return Auth.GROUP;
        } else if (uint8(bytes1(pt << 16)) > req) return Auth.USER;
        return Auth.UNKNOWN;
    }

    function isAuthenticated(
        address envoy,
        bytes4 sig,
        uint8 rootReq,
        uint8 groupReq,
        uint8 userReq
    ) public view returns (Auth) {
        bytes32 pt = table[envoy][sig];

        if (uint8(bytes1(pt)) > rootReq) return Auth.ROOT;
        else if (envoy.code.length != 0) {
            if (uint8(bytes1(pt << 8)) > groupReq) return Auth.GROUP;
        } else if (uint8(bytes1(pt << 16)) > userReq) return Auth.USER;
        return Auth.UNKNOWN;
    }

    function isRoot(address envoy, bytes4 sig) public view returns (bool authenticated) {
        authenticated = bytes1(table[envoy][sig]) > 0;
    }

    function isGroup(address envoy, bytes4 sig) public view returns (bool authenticated) {
        authenticated = bytes1(table[envoy][sig] << 8) > 0;
    }

    function isUser(address envoy, bytes4 sig) public view returns (bool authenticated) {
        authenticated = bytes1(table[envoy][sig] << 16) > 0;
    }
}
