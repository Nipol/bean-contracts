/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../interfaces/IERC721.sol";
import "../interfaces/IERC721Metadata.sol";
import "../interfaces/IERC721TokenReceiver.sol";
import "./ReentrantSafe.sol";

error ERC721_WrongERC721Receiver(address receiver);

error ERC721_NoneERC721Receiver(address receiver);

error ERC721_NotOwnerOrApprover(address caller);

error ERC721_NotAllowed(address caller, uint256 tokenId);

error ERC721_NotApproved(address operator, address caller);

error ERC721_NotExist(uint256 tokenId);

error ERC721_AlreadyExist(uint256 tokenId);

/**
 * @author yoonsung.eth
 * @notice ERC721의 모든 명세를 만족하는 구현체로써, NFT를 구성하는 외적 정보는 해당 라이브러리를 사용하는 유저가 구현하여 사용할 수 있도록 합니다.
 * @dev NFT는 추가발행될 필요가 있으므로 internal mint 함수를 포함하고 있으며, 이를 이용하는 라이브러리가 Ownership을 적절하게
 */
abstract contract ERC721 is IERC721, IERC721Metadata, ReentrantSafe {
    string public name;
    string public symbol;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public ownerOf;
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
                else revert ERC721_WrongERC721Receiver(to);
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721_NoneERC721Receiver(to);
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
    // function balanceOf(address target) public view virtual returns (uint256 count) {}
    // function ownerOf(uint256 tokenId) public view virtual returns (address target) {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable virtual {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert ERC721_NotOwnerOrApprover(msg.sender);
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
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert ERC721_NotOwnerOrApprover(msg.sender);
        _transfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public payable virtual {
        address _owner = ownerOf[tokenId];
        if (to == _owner) revert ERC721_NotAllowed(to, tokenId);
        if (msg.sender != _owner && !isApprovedForAll(_owner, msg.sender))
            revert ERC721_NotAllowed(msg.sender, tokenId);
        _approves[tokenId] = to;
        emit Approval(_owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        if (operator == msg.sender) revert ERC721_NotApproved(operator, msg.sender);
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
    // internal functions
    //------------------------------------------------------------------------------------------------------//
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (ownerOf[tokenId] != from) revert ERC721_NotAllowed(from, tokenId);
        if (to == address(0)) revert ERC721_NotAllowed(to, tokenId);
        _approves[tokenId] = address(0);
        ownerOf[tokenId] = to;

        unchecked {
            --balanceOf[from];
            ++balanceOf[to];
        }
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
        if (!_exists(tokenId)) revert ERC721_NotExist(tokenId);
        address _owner = ownerOf[tokenId];
        success = (spender == _owner) || (_approves[tokenId] == spender) || isApprovedForAll(_owner, spender);
    }

    function _exists(uint256 tokenId) internal view returns (bool exist) {
        exist = ownerOf[tokenId] != address(0);
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) revert ERC721_NotAllowed(to, tokenId);
        if (_exists(tokenId)) revert ERC721_AlreadyExist(tokenId);
        ownerOf[tokenId] = to;

        unchecked {
            balanceOf[to]++;
        }

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
        address _owner = ownerOf[tokenId];
        if (_owner == address(0)) revert ERC721_NotAllowed(_owner, tokenId);
        delete _approves[tokenId];
        delete ownerOf[tokenId];

        unchecked {
            balanceOf[_owner]--;
        }

        emit Transfer(_owner, address(0), tokenId);
    }
}
