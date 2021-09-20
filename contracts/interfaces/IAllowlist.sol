/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

interface IAllowlist {
    event Allowed(address indexed addr);
    event Revoked(address indexed addr);

    function allowance(address) external returns (bool);

    function authorise(address allowAddr) external;

    function revoke(address revokeAddr) external;
}
