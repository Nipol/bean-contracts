/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import {Ownership} from "./Ownership.sol";

/**
 * @title Authority
 * @author yoonsung.eth
 * @notice 컨트랙트에 대해 권리를 가지는 주체를 지정하고, 그 주체가 컨트랙트의 제한된 영역에 접근할 수 있는 인터페이스
 * signature(Role) + sender(Accesser)
 * 0x00000000 기본값, 
 */
abstract contract Authority is Ownership {

}
