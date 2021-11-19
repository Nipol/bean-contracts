/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.0;

interface IURI {
    function tokenURI(uint256 tokenId) external returns (string memory);
}
