/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";

error ERC20_ApproveToSelf();

/**
 * @title ERC20
 * @author yoonsung.eth
 * @notice Standard ERC20 specification implementation
 */
abstract contract ERC20 is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value) external virtual returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external virtual returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external virtual returns (bool) {
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual {
        balanceOf[from] -= value;
        unchecked {
            balanceOf[to] += value;
        }
        emit Transfer(from, to, value);
    }

    function _approve(
        address _owner,
        address spender,
        uint256 value
    ) internal virtual {
        if(spender == address(this)) revert ERC20_ApproveToSelf();
        allowance[_owner][spender] = value;
        emit Approval(_owner, spender, value);
    }
}
