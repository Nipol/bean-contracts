/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../library/Ownership.sol";
import "../library/ERC2612.sol";

contract TokenMock is ERC20, ERC2612, Ownership {
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        string memory tokenVersion
    ) {
        _initDomainSeparator(tokenName, tokenVersion);
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
        balanceOf[address(this)] = type(uint256).max;
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
}
