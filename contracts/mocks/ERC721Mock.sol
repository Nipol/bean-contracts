/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../library/Ownership.sol";
import "../library/ERC721.sol";

contract ERC721Mock is ERC721, Ownership {
    constructor(string memory nftName, string memory nftSymbol) {
        name = nftName;
        symbol = nftSymbol;
    }

    function mint(uint256 tokenId) external onlyOwner {
        _mint(msg.sender, tokenId);
    }

    function mintTo(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) external onlyOwner {
        _safeMint(to, tokenId, data);
    }

    function safeMint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId, "");
    }
}
