/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "./Ownership.sol";
import "../interfaces/IAllowlist.sol";

contract Allowlist is IAllowlist, Ownership {
    mapping(address => bool) public authority;

    constructor() Ownership() {}

    function authorise(address allowAddr) external onlyOwner {
        require(authority[allowAddr] == false, "Allowlist/Already-Authorized");
        authority[allowAddr] = true;
        emit Allowed(allowAddr);
    }

    function revoke(address revokeAddr) external onlyOwner {
        require(authority[revokeAddr] == true, "Allowlist/Not-Authorized");
        delete authority[revokeAddr];
        emit Revoked(revokeAddr);
    }
}
