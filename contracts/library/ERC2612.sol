/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "./EIP712.sol";
import "./AbstractERC20.sol";
import "../interfaces/IERC2612.sol";

error ExpiredTime();

error InvalidSignature(address recovered);

/**
 * @title ERC2612
 * @notice Provide EIP 2612 details aka permit and smooth the approach process by signing
 * @dev Differences:
 * - Uses sequential nonce, which restricts transaction submission to one at a time, or else it will revert
 * - Has deadline (= validBefore - 1) but does not have validAfter
 * - Doesn't have a way to change allowance atomically to prevent ERC20 multiple withdrawal attacks
 */
abstract contract ERC2612 is IERC2612, AbstractERC20 {
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    bytes32 public DOMAIN_SEPARATOR;

    string public version;

    constructor(string memory _name, string memory _version) {
        _initDomainSeparator(_name, _version);
    }

    /**
     * @notice get nonce per user.
     */
    mapping(address => uint256) public nonces;

    /**
     * @notice Initialize EIP712 Domain Separator
     * @param _name        name of contract
     * @param _version     version of contract
     */
    function _initDomainSeparator(string memory _name, string memory _version) internal {
        version = _version;
        DOMAIN_SEPARATOR = EIP712.hashDomainSeperator(_name, _version, address(this));
    }

    /**
     * @notice Verify a signed approval permit and execute if valid
     * @param owner     Token owner's address (Authorizer)
     * @param spender   Spender's address
     * @param value     Amount of allowance
     * @param deadline  The time at which this expires (unix time)
     * @param v         v of the signature
     * @param r         r of the signature
     * @param s         s of the signature
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual {
        if (deadline < block.timestamp) revert ExpiredTime();

        unchecked {
            uint256 nonce = nonces[owner]++;
            bytes32 digest = EIP712.hashMessage(
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline))
            );

            address recovered = ecrecover(digest, v, r, s);
            if (recovered == address(0) || recovered != owner) revert InvalidSignature(recovered);
        }

        _approve(owner, spender, value);
    }
}
