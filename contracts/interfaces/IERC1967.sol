/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

interface IERC1967 {
    event Upgraded(address indexed implementation);
    event BeaconUpgraded(address indexed beacon);
    event AdminChanged(address previousAdmin, address newAdmin);
}
