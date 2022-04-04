/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../library/Ownership.sol";
import {IERC721, ERC721} from "../library/ERC721.sol";
import {ERC4494} from "../library/ERC4494.sol";

contract NFTPermitMock is ERC721, ERC4494, Ownership {
    constructor(string memory nftName, string memory nftSymbol) {
        name = nftName;
        symbol = nftSymbol;
        _initDomainSeparator(name, "1");
    }

    function mint(uint256 tokenId) external {
        _mint(msg.sender, tokenId);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    function tokenURI(uint256) external pure returns (string memory) {
        return "";
    }
}
