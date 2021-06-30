/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "./Ownership.sol";
import "./Interface/IAllowlist.sol";

contract Allowlist is IAllowlist, Ownership {
    mapping(address => bool) public override allowance;

    constructor() {
        Ownership.initialize(msg.sender);
    }

    function authorise(address allowAddr) external override onlyOwner {
        allowance[allowAddr] = true;
        emit Allowed(allowAddr);
    }

    function revoke(address revokeAddr) external override onlyOwner {
        delete allowance[revokeAddr];
        emit Revoked(revokeAddr);
    }
}
