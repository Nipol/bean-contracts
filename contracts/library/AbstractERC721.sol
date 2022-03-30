/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

abstract contract AbstractERC721 {
    function _approve(
        address owner,
        address to,
        uint256 tokenId
    ) internal virtual;
}
