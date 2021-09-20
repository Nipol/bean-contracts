/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "./Ownership.sol";
import "../interfaces/IAllowlist.sol";

contract Allowlist is IAllowlist, Ownership {
    mapping(address => bool) public override allowance;

    constructor() Ownership() {}

    function authorise(address allowAddr) external override onlyOwner {
        require(allowance[allowAddr] == false, "Allowlist/Already-Authorized");
        allowance[allowAddr] = true;
        emit Allowed(allowAddr);
    }

    function revoke(address revokeAddr) external override onlyOwner {
        require(allowance[revokeAddr] == true, "Allowlist/Not-Authorized");
        delete allowance[revokeAddr];
        emit Revoked(revokeAddr);
    }
}
