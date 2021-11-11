/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../interfaces/IERC721.sol";
import "../interfaces/IERC721Enumerable.sol";
import "../interfaces/IERC721Metadata.sol";
import "../interfaces/IERC721TokenReceiver.sol";
import "./Address.sol";

abstract contract ERC721 is IERC721Metadata, IERC721Enumerable, IERC721 {
    using Address for address;

    address[] private _owners;
    address[] private _approves;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    //------------------------------------------------------------------------------------------------------//
    // ERC721 Metadata Specification.
    //------------------------------------------------------------------------------------------------------//
    function name() external view virtual returns (string memory _name) {}

    function symbol() external view virtual returns (string memory _symbol) {}

    function tokenURI(uint256 tokenId) external view virtual returns (string memory) {}

    //------------------------------------------------------------------------------------------------------//
    // ERC721 Specification.
    //------------------------------------------------------------------------------------------------------//
    function balanceOf(address owner) public view virtual returns (uint256 count) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        for (uint256 i = 0; i < _owners.length; i++) {
            if (owner == _owners[i]) count++;
        }
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address owner) {
        owner = _owners[tokenId];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public payable virtual {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: Not Owner");
        _approves[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address allowance) {
        allowance = _approves[tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) public view virtual returns (bool success) {
        success = _operatorApprovals[_owner][_operator];
    }

    //------------------------------------------------------------------------------------------------------//
    // ERC721 Enumerable Specification.
    //------------------------------------------------------------------------------------------------------//
    function totalSupply() public view virtual returns (uint256) {
        return _owners.length;
    }

    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        require(_exists(index), "ERC721: approved query for nonexistent token");
        return index;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256 tokenId) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        uint256 count;
        for (uint256 i; i < _owners.length; i++) {
            if (owner == _owners[i]) {
                if (count == index) return i;
                else count++;
            }
        }
        require(false, "ERC721Enumerable: owner index out of bounds");
    }

    //------------------------------------------------------------------------------------------------------//
    // internal functions
    //------------------------------------------------------------------------------------------------------//
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(_owners[tokenId] == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        approve(address(0), tokenId);
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Receive(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _checkOnERC721Receive(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal returns (bool success) {
        if (to.isContract()) {
            try IERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                success = retval == IERC721TokenReceiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                // revert called without a message
                if (reason.length < 68) revert();
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    reason := add(reason, 0x04)
                }
                revert(abi.decode(reason, (string)));
            }
        }
        return true;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool success) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        success = (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _exists(uint256 index) private view returns (bool exist) {
        exist = _owners[index] != address(0);
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _owners.push(to);

        emit Transfer(address(0), to, tokenId);
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Receive(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        approve(address(0), tokenId);
        _owners[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }
}
