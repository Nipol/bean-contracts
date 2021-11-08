/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../library/Ownership.sol";

contract TokenMock is IERC20, Ownership {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) {
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
        balanceOf[address(this)] = type(uint256).max;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }

    function mint(uint256 value) external onlyOwner returns (bool) {
        balanceOf[msg.sender] += value;
        totalSupply += value;
        emit Transfer(address(0), msg.sender, value);
        return true;
    }

    function mintTo(address to, uint256 value) external onlyOwner returns (bool) {
        balanceOf[to] += value;
        totalSupply += value;
        emit Transfer(address(0), to, value);
        return true;
    }

    function burn(uint256 value) external onlyOwner returns (bool) {
        balanceOf[msg.sender] -= value;
        totalSupply -= value;
        emit Transfer(msg.sender, address(0), value);
        return true;
    }

    function burnFrom(address from, uint256 value) external onlyOwner returns (bool) {
        allowance[from][msg.sender] -= value;
        balanceOf[from] -= value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function _approve(
        address _owner,
        address spender,
        uint256 value
    ) internal {
        require(spender != address(this), "ERC20/Impossible-Approve-to-Self");
        allowance[_owner][spender] = value;
        emit Approval(_owner, spender, value);
    }
}
