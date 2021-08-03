/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

/**
 * @title Beacon
 * @author yoonsung.eth
 * @notice Minimal Proxy를 위한 Beacon 컨트랙트이며 구현체 주소를 가지고 있음.
 */
contract Beacon {
    address public _implementation;
    address public immutable _CONTROLLER;
    
    constructor(address impl) {
        _implementation = impl;
        _CONTROLLER = msg.sender;
    }
    
    fallback() external {
        if (msg.sender != _CONTROLLER) {
            // solhint-disable-next-line no-inline-assembly
          assembly {
            mstore(0, sload(0))
            return(0, 32)
          }
        } else {
            // solhint-disable-next-line no-inline-assembly
          assembly { sstore(0, calldataload(0)) }
        }
    }
}