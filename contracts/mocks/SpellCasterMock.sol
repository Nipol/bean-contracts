/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../library/Caster.sol";

/**
 * @title SpellCasterMock
 * @author yoonsung.eth
 * @notice Contract가 할 수 있는 모든 호출을 담당함.
 */
contract SpellCasterMock is Caster {
    string public name = "SpellCaster";

    function casting(address[] calldata libraries, bytes[] calldata calls) external {
        cast(libraries, calls);
    }
}
