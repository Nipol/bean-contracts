/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

contract EtherSpell {
    function balanceOf(address to) external view returns (uint256 bal) {
        bal = to.balance;
    }

    function transfer(address payable to, uint256 amount) external {
        to.transfer(amount);
    }

    function send(address payable to, uint256 amount) external returns (bool suc) {
        suc = to.send(amount);
    }

    function balance() external view returns (uint256 bal) {
        bal = address(this).balance;
    }
}
