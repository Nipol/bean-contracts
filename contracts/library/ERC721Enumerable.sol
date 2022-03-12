/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../interfaces/IERC721.sol";
import "../interfaces/IERC721Enumerable.sol";
import "../interfaces/IERC721Metadata.sol";
import "../interfaces/IERC721TokenReceiver.sol";
import "./ReentrantSafe.sol";

/**
 * @author yoonsung.eth
 * @notice ERC721의 모든 명세를 만족하는 구현체로써, NFT를 구성하는 외적 정보는 해당 라이브러리를 사용하는 유저가 구현하여 사용할 수 있도록 합니다.
 * @dev NFT는 추가발행될 필요가 있으므로 internal mint 함수를 포함하고 있으며, 이를 이용하는 라이브러리가 Ownership을 적절하게
 */
abstract contract ERC721Enumerable is IERC721Metadata, IERC721Enumerable, ReentrantSafe, IERC721 {
    string public name;
    string public symbol;
    address[] private _owners;
    mapping(uint256 => address) private _approves;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @notice 해당 컨트랙트와 상호작용 하는 대상이 컨트랙트인 경우, NFT를 컨트롤 할 수 있는
     */
    modifier checkERC721Receive(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) {
        _;
        if (to.code.length != 0) {
            try IERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                if (retval == IERC721TokenReceiver.onERC721Received.selector) return;
                else revert("ERC721: transfer to wrong ERC721Receiver implementer");
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    //------------------------------------------------------------------------------------------------------//
    // ERC721 Specification.
    //------------------------------------------------------------------------------------------------------//
    function balanceOf(address target) public view virtual returns (uint256 count) {
        if (target == address(0)) return 0;
        address[] memory owners = _owners;
        uint256 length = owners.length;
        address owneri;

        for (uint256 i; i != length;) {
            owneri = owners[i];
            unchecked {
                if (target == owneri) count++;
            }
            
            unchecked {
                ++i;
            }
        }
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address target) {
        if (tokenId < _owners.length) return _owners[tokenId];
        else return address(0);
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
        address _owner = _owners[tokenId];
        require(to != _owner, "ERC721: approval to current owner");
        require(msg.sender == _owner || isApprovedForAll(_owner, msg.sender), "ERC721: Not Owner");
        _approves[tokenId] = to;
        emit Approval(_owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address allowance) {
        allowance = _approves[tokenId];
    }

    function isApprovedForAll(address target, address operator) public view virtual returns (bool success) {
        success = _operatorApprovals[target][operator];
    }

    //------------------------------------------------------------------------------------------------------//
    // ERC721 Enumerable Specification.
    //------------------------------------------------------------------------------------------------------//
    function totalSupply() public view virtual returns (uint256 total) {
        address[] memory owners = _owners;
        uint256 length = _owners.length;
        
        for (uint256 i; i != length;) {
            unchecked {
                if (owners[i] != address(0)) total++;
            }

            unchecked {
                ++i;
            }
        }
    }

    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        require(index < _owners.length, "ERC721: approved query for nonexistent token");
        return index;
    }

    function tokenOfOwnerByIndex(address target, uint256 index) public view virtual returns (uint256 tokenId) {
        require(index < balanceOf(target), "ERC721Enumerable: owner index out of bounds");
        uint256 count;
        address[] memory owners = _owners;
        uint256 length = owners.length;
        
        for (uint256 i; i != length;) {
            unchecked {
                if (target == owners[i]) {
                    if (count == index) return i;
                    else count++;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    //------------------------------------------------------------------------------------------------------//
    // internal functions
    //------------------------------------------------------------------------------------------------------//
    function _nextId() internal view returns (uint256 id) {
        id = _owners.length;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(_owners[tokenId] == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        _approves[tokenId] = address(0);
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual reentrantSafer checkERC721Receive(from, to, tokenId, _data) {
        _transfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool success) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address _owner = _owners[tokenId];
        success = (spender == _owner) || (_approves[tokenId] == spender) || isApprovedForAll(_owner, spender);
    }

    function _exists(uint256 tokenId) internal view returns (bool exist) {
        exist = (tokenId < _owners.length) && (_owners[tokenId] != address(0));
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
    ) internal virtual reentrantSafer checkERC721Receive(address(0), to, tokenId, _data) {
        _mint(to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address _owner = _owners[tokenId];
        _approves[tokenId] = address(0);
        delete _owners[tokenId];

        emit Transfer(_owner, address(0), tokenId);
    }
}
