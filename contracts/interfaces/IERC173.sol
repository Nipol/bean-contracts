/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

/**
 * @title ERC-173 Contract Ownership Standard
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-173.md
 * Note: the ERC-165 identifier for this interface is 0x7f5828d0
 */
interface IERC173 {
    /**
     * @dev This emits when ownership of a contract changes.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @notice Get the address of the owner
     * @return The address of the owner.
     */
    function owner() external view returns (address);

    /**
     * @notice Set the address of the new owner of the contract
     * @param newOwner The address of the new owner of the contract
     */
    function transferOwnership(address newOwner) external;
}
