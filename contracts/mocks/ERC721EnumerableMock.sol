/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../library/Ownership.sol";
import {IERC721, ERC721Enumerable} from "../library/ERC721Enumerable.sol";

contract ERC721EnumerableMock is ERC721Enumerable, Ownership {
    constructor(string memory nftName, string memory nftSymbol) {
        name = nftName;
        symbol = nftSymbol;
    }

    function mint() external {
        _mint(msg.sender, _nextId());
    }

    function mintTo(address to) external {
        _mint(to, _nextId());
    }

    function safeMint(address to, bytes memory data) external {
        _safeMint(to, _nextId(), data);
    }

    function safeMint(address to) external {
        _safeMint(to, _nextId(), "");
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    function tokenURI(uint256) external pure returns (string memory) {
        return "";
    }
}
