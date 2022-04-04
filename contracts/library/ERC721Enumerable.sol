/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../interfaces/IERC721.sol";
import "../interfaces/IERC721Enumerable.sol";
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

error ERC721Enumerable__OutOfIndex(uint256 index);

/**
 * @author yoonsung.eth
 * @notice As an implementation that meets all the specifications of ERC721Enumerable,
 * the external information constituting NFT is implemented and available to users using the library.
 * @dev As some NFTs are continuously additionally issued, this library include an internal mint function,
 * and the contract using it must properly tune Ownership.
 */
abstract contract ERC721Enumerable is IERC721, IERC721Metadata, IERC721Enumerable, ReentrantSafe, AbstractERC721 {
    string public name;
    string public symbol;
    address[] private _owners;
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
    function balanceOf(address target) public view virtual returns (uint256 count) {
        if (target == address(0)) return 0;
        address[] memory owners = _owners;
        uint256 length = owners.length;
        address owneri;

        for (uint256 i; i != length; ) {
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
        address _owner = _owners[tokenId];
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
    // ERC721 Enumerable Specification.
    //------------------------------------------------------------------------------------------------------//
    function totalSupply() public view virtual returns (uint256 total) {
        address[] memory owners = _owners;
        uint256 length = _owners.length;

        for (uint256 i; i != length; ) {
            unchecked {
                if (owners[i] != address(0)) total++;
            }

            unchecked {
                ++i;
            }
        }
    }

    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        if (index >= _owners.length) revert ERC721__NotExist(index);
        return index;
    }

    function tokenOfOwnerByIndex(address target, uint256 index) public view virtual returns (uint256 tokenId) {
        if (index >= balanceOf(target)) revert ERC721Enumerable__OutOfIndex(index);
        uint256 count;
        address[] memory owners = _owners;
        uint256 length = owners.length;

        for (uint256 i; i != length; ) {
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
        if (_owners[tokenId] != from) revert ERC721__NotAllowed(from, tokenId);
        if (to == address(0)) revert ERC721__NotAllowed(to, tokenId);
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

    function _approve(
        address owner,
        address to,
        uint256 tokenId
    ) internal override {
        _approves[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool success) {
        if (!_exists(tokenId)) revert ERC721__NotExist(tokenId);
        address _owner = _owners[tokenId];
        success = (spender == _owner) || (_approves[tokenId] == spender) || isApprovedForAll(_owner, spender);
    }

    function _exists(uint256 tokenId) internal view returns (bool exist) {
        exist = (tokenId < _owners.length) && (_owners[tokenId] != address(0));
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) revert ERC721__NotAllowed(to, tokenId);
        if (_exists(tokenId)) revert ERC721__AlreadyExist(tokenId);

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
        if (_owner == address(0)) revert ERC721__NotAllowed(_owner, tokenId);
        _approves[tokenId] = address(0);
        delete _owners[tokenId];

        emit Transfer(_owner, address(0), tokenId);
    }
}
