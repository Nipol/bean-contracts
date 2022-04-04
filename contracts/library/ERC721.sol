/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../interfaces/IERC721.sol";
import "../interfaces/IERC721Metadata.sol";
import "../interfaces/IERC721TokenReceiver.sol";
import "./AbstractERC721.sol";
import "./ReentrantSafe.sol";

error ERC721__WrongERC721Receiver(address receiver);

error ERC721__NoneERC721Receiver(address receiver);

error ERC721__NotOwnerOrApprover(address caller);

error ERC721__NotAllowed(address caller, uint256 tokenId);

error ERC721__NotApproved(address operator, address caller);

error ERC721__NotExist(uint256 tokenId);

error ERC721__AlreadyExist(uint256 tokenId);

/**
 * @author yoonsung.eth
 * @notice As an implementation that meets all the specifications of ERC721,
 * the external information constituting NFT is implemented and available to users using the library.
 * @dev As some NFTs are continuously additionally issued, this library include an internal mint function,
 * and the contract using it must properly tune Ownership.
 */
abstract contract ERC721 is IERC721, IERC721Metadata, ReentrantSafe, AbstractERC721 {
    string public name;
    string public symbol;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => address) private _approves;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @notice 해당 NFT와 상호작용 하는 대상이 컨트랙트인 경우, NFT를 컨트롤 할 수 있는 인터페이스가 있는지 확인.
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
                else revert ERC721__WrongERC721Receiver(to);
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721__NoneERC721Receiver(to);
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
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert ERC721__NotOwnerOrApprover(msg.sender);
        _safeTransfer(from, to, tokenId, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert ERC721__NotOwnerOrApprover(msg.sender);
        _safeTransfer(from, to, tokenId, "");
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert ERC721__NotOwnerOrApprover(msg.sender);
        _transfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public payable virtual {
        address _owner = ownerOf[tokenId];
        if (to == _owner) revert ERC721__NotAllowed(to, tokenId);
        if (msg.sender != _owner && !isApprovedForAll(_owner, msg.sender))
            revert ERC721__NotAllowed(msg.sender, tokenId);
        _approve(_owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        if (operator == msg.sender) revert ERC721__NotApproved(operator, msg.sender);
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
        if (ownerOf[tokenId] != from) revert ERC721__NotAllowed(from, tokenId);
        if (to == address(0)) revert ERC721__NotAllowed(to, tokenId);
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

    function _approve(
        address owner,
        address to,
        uint256 tokenId
    ) internal override {
        _approves[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool success) {
        if (!_exists(tokenId)) revert ERC721__NotExist(tokenId);
        address _owner = ownerOf[tokenId];
        success = (spender == _owner) || isApprovedForAll(_owner, spender) || (_approves[tokenId] == spender);
    }

    function _exists(uint256 tokenId) internal view returns (bool exist) {
        exist = ownerOf[tokenId] != address(0);
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) revert ERC721__NotAllowed(to, tokenId);
        if (_exists(tokenId)) revert ERC721__AlreadyExist(tokenId);
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
        if (_owner == address(0)) revert ERC721__NotAllowed(_owner, tokenId);
        delete _approves[tokenId];
        delete ownerOf[tokenId];

        unchecked {
            balanceOf[_owner]--;
        }

        emit Transfer(_owner, address(0), tokenId);
    }
}
