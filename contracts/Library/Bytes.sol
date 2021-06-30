/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

library Bytes {
    function mergeSignature(
        uint8 r,
        bytes32 s,
        bytes32 v
    ) internal pure returns (bytes memory signature) {
        signature = new bytes(65);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(add(signature, 32), r)
            mstore(add(signature, 64), s)
            mstore(add(signature, 65), v)
        }

        return signature;
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        if (sig.length == 65) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                // first 32 bytes, after the length prefix.
                r := mload(add(sig, 32))
                // second 32 bytes.
                s := mload(add(sig, 64))
                // final byte (first byte of the next 32 bytes).
                v := byte(0, mload(add(sig, 96)))
            }
        } else if (sig.length == 64) {
            bytes32 vs;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                // first 32 bytes, after the length prefix.
                r := mload(add(sig, 32))
                // second 32 bytes.
                vs := mload(add(sig, 64))
            }
            s =
                vs &
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
            v = 27 + uint8(uint256(vs) >> 255);
        }

        return (v, r, s);
    }
}
