/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";

contract ERC20SpellMock {
    function balanceOf(IERC20 ERC20, address target) external view returns (uint256) {
        return ERC20.balanceOf(target);
    }

    function allowance(
        IERC20 ERC20,
        address owner,
        address spender
    ) external view returns (uint256) {
        return ERC20.allowance(owner, spender);
    }

    function transfer(
        IERC20 ERC20,
        address to,
        uint256 value
    ) external returns (bool) {
        return ERC20.transfer(to, value);
    }

    function transferFrom(
        IERC20 ERC20,
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        return ERC20.transferFrom(from, to, value);
    }

    function approve(
        IERC20 ERC20,
        address spender,
        uint256 value
    ) external returns (bool) {
        return ERC20.approve(spender, value);
    }
}
