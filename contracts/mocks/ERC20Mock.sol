/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../Library/ERC2612.sol";

contract ERC20Mock is ERC2612 {
    mapping(address => mapping(address => uint256)) public allowance;

    string public name = "Mock";

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor() {
        _initDomainSeparator(name, "1");
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        _permit(owner, spender, value, deadline, v, r, s);
        emit Approval(owner, spender, value);
    }

    function _approve(address owner, address spender, uint256 amount) internal override {
        allowance[owner][spender] = amount;
    }

    function _transfer(address from, address to, uint256 value) internal override {
    }
}