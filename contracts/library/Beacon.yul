/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

/// 0x606161002960003933600081816002015260310152602080380360803960805160005560616000f3fe337f00000000000000000000000000000000000000000000000000000000000000001415602e57600035600055005b337f00000000000000000000000000000000000000000000000000000000000000001460605760005460005260206000f35b
/**
 * @title Beacon
 * @author yoonsung.eth
 * @notice for Beacon minimal proxy
 * @dev when deploy with this code, usage `abi.encodePacked(bytesCode, abi.encode(address(implementation)))`.
 * and controller can change the implementation, call `abi.encode(new implementation address)`
 */
object "Beacon" {
    code {
        datacopy(0, dataoffset("Runtime"), datasize("Runtime"))
        setimmutable(0, "controller", caller())
        // constructor(address implementation)
        codecopy(128, sub(codesize(), 32), 32)
        sstore(0, mload(128))
        return(0, datasize("Runtime"))
    }

    object "Runtime" {
        code {
            if eq(loadimmutable("controller"), caller()) {
                sstore(0, calldataload(0))
                stop()
            }

            if iszero(eq(loadimmutable("controller"), caller())) {
                mstore(0, sload(0))
                return(0, 32)
            }
        }
    }
}
