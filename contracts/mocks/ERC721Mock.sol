/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../library/ERC721.sol";

contract ERC721Mock is ERC721 {
    string public override name;
    string public override symbol;

    constructor(string memory nftName, string memory nftSymbol) {
        name = nftName;
        symbol = nftSymbol;
    }
}
