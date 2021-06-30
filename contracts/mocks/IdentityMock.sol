/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../Interface/IERC1271.sol";

contract IdentityMock is IERC1271 {
    mapping(address => bool) public owners;

    bytes4 internal constant MAGICVALUE =
        bytes4(keccak256("isValidSignature(bytes,bytes)"));
    bytes4 internal constant NOT_MAGICVALUE = 0xffffffff;

    constructor() {
        owners[msg.sender] = true;
    }

    function isValidSignature(bytes memory digest, bytes memory signature)
        external
        view
        override
        returns (bytes4)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 255)
        }
        if (v < 27) v += 27;

        // digest bytes to bytes32
        bytes32 _digest;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            _digest := mload(add(digest, 32))
        }
        address recovered = ecrecover(_digest, v, r, s);

        if (recovered == address(0) || owners[recovered] == false) {
            return NOT_MAGICVALUE;
        }
        return MAGICVALUE;
    }
}
