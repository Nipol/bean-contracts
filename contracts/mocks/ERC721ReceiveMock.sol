/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../interfaces/IERC721TokenReceiver.sol";

contract ERC721ReceiveMock is IERC721TokenReceiver {
    uint256 public counter;

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory data
    ) external returns (bytes4) {
        assembly {
            sstore(counter.offset, mload(add(data, 0x20)))
        }
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

contract NoneERC721ReceiveMock is IERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)asdf"));
    }
}

contract RevertERC721ReceiveMock is IERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        revert("Slurp");
    }
}
