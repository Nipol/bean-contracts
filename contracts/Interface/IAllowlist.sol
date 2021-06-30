/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../Library/Ownership.sol";

interface IAllowlist {
    event Allowed(address addr);
    event Revoked(address addr);

    function allowance(address) external returns (bool);

    function authorise(address allowAddr) external;

    function revoke(address revokeAddr) external;
}
