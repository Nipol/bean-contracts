/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../Interface/IERC173.sol";

contract Ownership is IERC173 {
    address private _owner;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownership/Not-Authorized");
        _;
    }

    function initialize(address newOwner) internal {
        _owner = newOwner;
        emit OwnershipTransferred(address(0), newOwner);
    }

    function owner() external view override returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner)
        external
        override
        onlyOwner
    {
        _owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}
