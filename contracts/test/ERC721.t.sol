/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "../interfaces/IERC721TokenReceiver.sol";
import {IERC721, ERC721Mock} from "../mocks/ERC721Mock.sol";
import {ExploitERC721Mint} from "../mocks/ExploitERC721Mint.sol";
import {ExploitMinter} from "../mocks/ExploitMinter.sol";

interface CheatCodes {
    function prank(address) external;

    function expectRevert(bytes calldata) external;
}

contract ERC721Receiver is IERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return IERC721TokenReceiver.onERC721Received.selector;
    }
}

contract WrongERC721Receiver is IERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return 0xBEEFDEAD;
    }
}

contract RevertERC721Receiver is IERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        revert("Peek A Boo");
    }
}

contract ReentrantERC721Receiver is IERC721TokenReceiver {
    IERC721 nft;

    constructor(address nftaddr) {
        nft = IERC721(nftaddr);
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes memory
    ) external returns (bytes4) {
        // or
        nft.safeTransferFrom(address(this), address(1), tokenId);
        return IERC721TokenReceiver.onERC721Received.selector;
    }
}

contract NoneERC721Receiver {}

contract ERC721Test is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    ERC721Mock nft;

    function setUp() public {
        nft = new ERC721Mock("NFT", "NFT Symbol");
    }

    function testInvariantMetadata() public {
        assertEq(nft.name(), "NFT");
        assertEq(nft.symbol(), "NFT Symbol");
    }

    function testBalanceOf() public {
        assertEq(nft.balanceOf(address(0xDEADBEEF)), 0);
        unchecked {
            for (uint256 i; i < 10; i++) {
                nft.mintTo(address(0xDEADBEEF), i);
            }
        }

        unchecked {
            for (uint256 i; i < 100; i++) {
                nft.mint(10 + i);
            }
        }

        unchecked {
            for (uint256 i; i < 10; i++) {
                nft.mintTo(address(0xDEADBEEF), 110 + i);
            }
        }
        assertEq(nft.balanceOf(address(0xDEADBEEF)), 20);
    }

    function testMint() public {
        assertEq(nft.balanceOf(address(0xDEADBEEF)), 0);

        nft.mintTo(address(0xDEADBEEF), 0);

        assertEq(nft.balanceOf(address(0xDEADBEEF)), 1);
        assertEq(nft.ownerOf(0), address(0xDEADBEEF));
    }

    function testBurn() public {
        nft.mintTo(address(0xDEADBEEF), 0);

        nft.burn(0);

        assertEq(nft.balanceOf(address(0xDEADBEEF)), 0);
        assertEq(nft.ownerOf(0), address(0));
    }

    function testApprove() public {
        nft.mint(0);

        nft.approve(address(0xDEADBEEF), 0);

        assertEq(nft.getApproved(0), address(0xDEADBEEF));
    }

    function testApprovedBurn() public {
        nft.mint(0);

        nft.approve(address(0xDEADBEEF), 0);

        nft.burn(0);

        assertEq(nft.getApproved(0), address(0));
    }

    function testTransferFrom() public {
        nft.mint(0);

        nft.transferFrom(address(this), address(0xDEADBEEF), 0);

        assertEq(nft.balanceOf(address(0xDEADBEEF)), 1);
        assertEq(nft.ownerOf(0), address(0xDEADBEEF));
    }

    function testApproveAndTransferFrom() public {
        nft.mintTo(address(0xDEADBEEF), 0);

        cheats.prank(address(0xDEADBEEF));
        nft.approve(address(this), 0);

        nft.transferFrom(address(0xDEADBEEF), address(this), 0);

        assertEq(nft.balanceOf(address(this)), 1);
        assertEq(nft.ownerOf(0), address(this));
        assertEq(nft.getApproved(0), address(0));
    }

    function testSafeMintToEligibleContract() public {
        ERC721Receiver r = new ERC721Receiver();
        assertEq(nft.balanceOf(address(r)), 0);

        nft.safeMint(address(r), 0);

        assertEq(nft.balanceOf(address(r)), 1);
        assertEq(nft.ownerOf(0), address(r));
    }

    function testSafeMintToNotEligibleContract() public {
        WrongERC721Receiver r = new WrongERC721Receiver();
        assertEq(nft.balanceOf(address(r)), 0);

        cheats.expectRevert(bytes("ERC721: transfer to wrong ERC721Receiver implementer"));
        nft.safeMint(address(r), 0);

        assertEq(nft.balanceOf(address(r)), 0);
    }

    function testSafeMintToRevertContract() public {
        RevertERC721Receiver r = new RevertERC721Receiver();
        assertEq(nft.balanceOf(address(r)), 0);

        cheats.expectRevert(bytes("Peek A Boo"));
        nft.safeMint(address(r), 0);

        assertEq(nft.balanceOf(address(r)), 0);
    }

    function testSafeMintToNotReceiverContract() public {
        NoneERC721Receiver r = new NoneERC721Receiver();
        assertEq(nft.balanceOf(address(r)), 0);

        cheats.expectRevert(bytes("ERC721: transfer to none ERC721Receiver implementer"));
        nft.safeMint(address(r), 0);

        assertEq(nft.balanceOf(address(r)), 0);
    }

    function testFailSafeMintToReentrantReceiverContract() public {
        ExploitERC721Mint exploitNFT = new ExploitERC721Mint();
        ExploitMinter r = new ExploitMinter(address(exploitNFT));
        assertEq(exploitNFT.balanceOf(address(r)), 0);

        r.toMinter();

        assertEq(exploitNFT.balanceOf(address(r)), 0);
    }

    function testSafeTransferFromToEligibleContract() public {
        ERC721Receiver r = new ERC721Receiver();
        nft.mint(0);
        assertEq(nft.balanceOf(address(r)), 0);

        nft.safeTransferFrom(address(this), address(r), 0);

        assertEq(nft.balanceOf(address(r)), 1);
        assertEq(nft.ownerOf(0), address(r));
    }

    function testSafeTransferFromToNotEligibleContract() public {
        WrongERC721Receiver r = new WrongERC721Receiver();
        nft.mint(0);
        assertEq(nft.balanceOf(address(r)), 0);

        cheats.expectRevert(bytes("ERC721: transfer to wrong ERC721Receiver implementer"));
        nft.safeTransferFrom(address(this), address(r), 0);

        assertEq(nft.balanceOf(address(r)), 0);
    }

    function testSafeTransferFromToRevertContract() public {
        RevertERC721Receiver r = new RevertERC721Receiver();
        nft.mint(0);
        assertEq(nft.balanceOf(address(r)), 0);

        cheats.expectRevert(bytes("Peek A Boo"));
        nft.safeTransferFrom(address(this), address(r), 0);

        assertEq(nft.balanceOf(address(r)), 0);
    }

    function testSafeTransferFromToNotReceiverContract() public {
        NoneERC721Receiver r = new NoneERC721Receiver();
        nft.mint(0);
        assertEq(nft.balanceOf(address(r)), 0);

        cheats.expectRevert(bytes("ERC721: transfer to none ERC721Receiver implementer"));
        nft.safeTransferFrom(address(this), address(r), 0);

        assertEq(nft.balanceOf(address(r)), 0);
    }
}
