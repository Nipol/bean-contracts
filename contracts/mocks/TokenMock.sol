/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../interfaces/IMint.sol";
import "../interfaces/IBurn.sol";
import "../interfaces/IERC165.sol";
import {ERC20, IERC20} from "../library/ERC20.sol";
import {ERC2612, IERC2612} from "../library/ERC2612.sol";
import {Ownership, IERC173} from "../library/Ownership.sol";
import {Multicall, IMulticall} from "../library/Multicall.sol";

contract TokenMock is ERC20, ERC2612, Ownership, Multicall, IBurn, IMint, IERC165 {
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

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            // ERC20
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IMint).interfaceId ||
            interfaceId == type(IBurn).interfaceId ||
            // ERC2612
            interfaceId == type(IERC2612).interfaceId ||
            // ITemplateV1(ERC165, ERC173, IMulticall)
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC173).interfaceId ||
            interfaceId == type(IMulticall).interfaceId;
    }
}
