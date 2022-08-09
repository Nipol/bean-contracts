/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../interfaces/IERC721TokenReceiver.sol";
import {IERC721, ERC721EnumerableMock} from "../mocks/ERC721EnumerableMock.sol";
import {ExploitERC721Mint} from "../mocks/ExploitERC721Mint.sol";
import {ExploitMinter} from "../mocks/ExploitMinter.sol";

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
        nft.safeTransferFrom(address(this), address(10), tokenId);
        return IERC721TokenReceiver.onERC721Received.selector;
    }
}

contract NoneERC721Receiver {}

contract ERC721EnumerableTest is Test {
    ERC721EnumerableMock nft;

    function setUp() public {
        nft = new ERC721EnumerableMock("NFT", "NFT Symbol");
    }

    function testInvariantMetadata() public {
        assertEq(nft.name(), "NFT");
        assertEq(nft.symbol(), "NFT Symbol");
    }

    function testTotalSupply() public {
        assertEq(nft.totalSupply(), 0);

        unchecked {
            for (uint256 i; i < 10; i++) {
                nft.mintTo(address(0xDEADBEEF));
            }
        }

        unchecked {
            for (uint256 i; i < 5; i++) {
                nft.burn(i);
            }
        }
        assertEq(nft.totalSupply(), 5);
    }

    function testBalanceOf() public {
        assertEq(nft.balanceOf(address(0xDEADBEEF)), 0);
        unchecked {
            for (uint256 i; i < 10; i++) {
                nft.mintTo(address(0xDEADBEEF));
            }
        }

        unchecked {
            for (uint256 i; i < 100; i++) {
                nft.mint();
            }
        }

        unchecked {
            for (uint256 i; i < 10; i++) {
                nft.mintTo(address(0xDEADBEEF));
            }
        }
        assertEq(nft.balanceOf(address(0xDEADBEEF)), 20);
    }

    function testMint() public {
        assertEq(nft.balanceOf(address(0xDEADBEEF)), 0);

        nft.mintTo(address(0xDEADBEEF));

        assertEq(nft.balanceOf(address(0xDEADBEEF)), 1);
        assertEq(nft.ownerOf(0), address(0xDEADBEEF));
    }

    function testBurn() public {
        nft.mintTo(address(0xDEADBEEF));

        nft.burn(0);

        assertEq(nft.balanceOf(address(0xDEADBEEF)), 0);
        assertEq(nft.ownerOf(0), address(0));
    }

    function testApprove() public {
        nft.mint();

        nft.approve(address(0xDEADBEEF), 0);

        assertEq(nft.getApproved(0), address(0xDEADBEEF));
    }

    function testApprovedBurn() public {
        nft.mint();

        nft.approve(address(0xDEADBEEF), 0);

        nft.burn(0);

        assertEq(nft.getApproved(0), address(0));
    }

    function testTransferFrom() public {
        nft.mint();

        nft.transferFrom(address(this), address(0xDEADBEEF), 0);

        assertEq(nft.balanceOf(address(0xDEADBEEF)), 1);
        assertEq(nft.ownerOf(0), address(0xDEADBEEF));
    }

    function testApproveAndTransferFrom() public {
        nft.mintTo(address(0xDEADBEEF));

        vm.prank(address(0xDEADBEEF));
        nft.approve(address(this), 0);

        nft.transferFrom(address(0xDEADBEEF), address(this), 0);

        assertEq(nft.balanceOf(address(this)), 1);
        assertEq(nft.ownerOf(0), address(this));
        assertEq(nft.getApproved(0), address(0));
    }

    function testSafeMintToEligibleContract() public {
        ERC721Receiver r = new ERC721Receiver();
        assertEq(nft.balanceOf(address(r)), 0);

        nft.safeMint(address(r));

        assertEq(nft.balanceOf(address(r)), 1);
        assertEq(nft.ownerOf(0), address(r));
    }

    function testSafeMintToNotEligibleContract() public {
        WrongERC721Receiver r = new WrongERC721Receiver();
        assertEq(nft.balanceOf(address(r)), 0);

        vm.expectRevert(
            abi.encodeWithSelector(bytes4(keccak256("ERC721__WrongERC721Receiver(address)")), address(r))
        );
        nft.safeMint(address(r));

        assertEq(nft.balanceOf(address(r)), 0);
    }

    function testSafeMintToRevertContract() public {
        RevertERC721Receiver r = new RevertERC721Receiver();
        assertEq(nft.balanceOf(address(r)), 0);

        vm.expectRevert(bytes("Peek A Boo"));
        nft.safeMint(address(r));

        assertEq(nft.balanceOf(address(r)), 0);
    }

    function testSafeMintToNotReceiverContract() public {
        NoneERC721Receiver r = new NoneERC721Receiver();
        assertEq(nft.balanceOf(address(r)), 0);

        vm.expectRevert(
            abi.encodeWithSelector(bytes4(keccak256("ERC721__NoneERC721Receiver(address)")), address(r))
        );
        nft.safeMint(address(r));

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
        nft.mint();
        assertEq(nft.balanceOf(address(r)), 0);

        nft.safeTransferFrom(address(this), address(r), 0);

        assertEq(nft.balanceOf(address(r)), 1);
        assertEq(nft.ownerOf(0), address(r));
    }

    function testSafeTransferFromToNotEligibleContract() public {
        WrongERC721Receiver r = new WrongERC721Receiver();
        nft.mint();
        assertEq(nft.balanceOf(address(r)), 0);

        vm.expectRevert(
            abi.encodeWithSelector(bytes4(keccak256("ERC721__WrongERC721Receiver(address)")), address(r))
        );
        nft.safeTransferFrom(address(this), address(r), 0);

        assertEq(nft.balanceOf(address(r)), 0);
    }

    function testSafeTransferFromToRevertContract() public {
        RevertERC721Receiver r = new RevertERC721Receiver();
        nft.mint();
        assertEq(nft.balanceOf(address(r)), 0);

        vm.expectRevert(bytes("Peek A Boo"));
        nft.safeTransferFrom(address(this), address(r), 0);

        assertEq(nft.balanceOf(address(r)), 0);
    }

    function testSafeTransferFromToNotReceiverContract() public {
        NoneERC721Receiver r = new NoneERC721Receiver();
        nft.mint();
        assertEq(nft.balanceOf(address(r)), 0);

        vm.expectRevert(
            abi.encodeWithSelector(bytes4(keccak256("ERC721__NoneERC721Receiver(address)")), address(r))
        );
        nft.safeTransferFrom(address(this), address(r), 0);

        assertEq(nft.balanceOf(address(r)), 0);
    }

    function testApprovalForAll() public {
        nft.mint();
        nft.setApprovalForAll(address(10), true);

        vm.prank(address(10));
        nft.transferFrom(address(this), address(2), 0);
        assertEq(nft.ownerOf(0), address(2));
        assertTrue(nft.isApprovedForAll(address(this), address(10)));
    }

    function testApprovalForAllToSelf() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                bytes4(keccak256("ERC721__NotApproved(address,address)")),
                address(this),
                address(this)
            )
        );
        nft.setApprovalForAll(address(this), true);
    }

    function testNotExistTransfer() public {
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("ERC721__NotExist(uint256)")), 0));
        nft.transferFrom(address(this), address(10), 0);
    }

    function testNotApprovedTransfer() public {
        nft.mintTo(address(10));
        vm.expectRevert(
            abi.encodeWithSelector(bytes4(keccak256("ERC721__NotOwnerOrApprover(address)")), address(this))
        );
        nft.transferFrom(address(this), address(2), 0);
    }

    function testTransferToZero() public {
        nft.mint();
        vm.expectRevert(
            abi.encodeWithSelector(bytes4(keccak256("ERC721__NotAllowed(address,uint256)")), address(0), 0)
        );
        nft.transferFrom(address(this), address(0), 0);
    }

    function testNotExistSafeTransfer() public {
        vm.expectRevert(abi.encodeWithSelector(bytes4(keccak256("ERC721__NotExist(uint256)")), 0));
        nft.safeTransferFrom(address(this), address(10), 0, "");
    }

    function testNotApprovedSafeTransfer() public {
        nft.mintTo(address(10));
        vm.expectRevert(
            abi.encodeWithSelector(bytes4(keccak256("ERC721__NotOwnerOrApprover(address)")), address(this))
        );
        nft.safeTransferFrom(address(this), address(2), 0, "");
    }

    function testSafeTransferToZero() public {
        nft.mint();
        vm.expectRevert(
            abi.encodeWithSelector(bytes4(keccak256("ERC721__NotAllowed(address,uint256)")), address(0), 0)
        );
        nft.safeTransferFrom(address(this), address(0), 0, "");
    }
}
