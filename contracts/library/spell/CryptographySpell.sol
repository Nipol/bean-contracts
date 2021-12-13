/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

contract CryptographySpell {
    function keccak256(bytes memory param) external pure returns (bytes32 ret) {
        ret = keccak256(param);
    }

    function sha256(bytes memory param) external pure returns (bytes32 ret) {
        ret = sha256(param);
    }

    function ripemd160(bytes memory param) external pure returns (bytes20 ret) {
        ret = ripemd160(param);
    }

    function ecrecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external pure returns (address addr) {
        addr = ecrecover(hash, v, r, s);
    }
}
