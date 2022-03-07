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
 0x0000
 앞 두 자리는 컨트랙트의 경우,
 뒷 두 자리는 일반 EOA인 경우,
 외부에서 특정 오브젝트에 대해 호출하는 경우. 특정함수 + 특정주소 + only EOA or only Contract
 0x0000000000000000000000000000000000000000000000000000000000000000
 0x00000000                b4c79daB8f259C7Aee6E5b2Aa729821864227e84
 그렇지만, 검색 자체가 sig로 부터 시작되어, 주소로 갈 수 있고,
 주소에서 sig갈 수도 있음...

 Root = 0xff
 user = 0x00 이상
 public 0x00
 */
abstract contract Authority is Ownership {
    function canCall(bytes4 sig, address caller) external returns (bool) {}
}
