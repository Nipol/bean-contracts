/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "./EIP712.sol";
import "./AbstractERC721.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC4494.sol";

import "hardhat/console.sol";

error ERC4494__ExpiredTime();

error ERC4494__InvalidSignature(address recovered);

/**
 * @title ERC4494
 * @notice Provide EIP 2612 details aka permit and smooth the approach process by signing
 * @dev Differences:
 * - Uses sequential nonce, which restricts transaction submission to one at a time, or else it will revert
 * - Has deadline (= validBefore - 1) but does not have validAfter
 * - Doesn't have a way to change allowance atomically to prevent ERC20 multiple withdrawal attacks
 */
abstract contract ERC4494 is IERC4494, AbstractERC721 {
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");

    bytes32 public DOMAIN_SEPARATOR;

    string public version;

    /**
     * @notice get nonce per tokenId.
     */
    mapping(uint256 => uint256) public nonces;

    /**
     * @notice Initialize EIP712 Domain Separator
     * @param _name        name of contract
     * @param _version     version of contract
     */
    function _initDomainSeparator(string memory _name, string memory _version) internal {
        version = _version;
        DOMAIN_SEPARATOR = EIP712.hashDomainSeperator(_name, _version, address(this));
    }

    /// @notice Function to approve by way of owner signature
    /// @param spender the address to approve
    /// @param tokenId the index of the NFT to approve the spender on
    /// @param deadline a timestamp expiry for the permit
    /// @param signature a traditional or EIP-2098 signature
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) external virtual {
        if (deadline < block.timestamp) revert ERC4494__ExpiredTime();

        uint8 v;
        bytes32 r;
        bytes32 s;

        if (signature.length == 65) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 32))
                s := mload(add(signature, 64))
                v := byte(0, mload(add(signature, 96)))
            }
        } else if (signature.length == 64) {
            bytes32 vs;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 32))
                vs := mload(add(signature, 64))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            }
            unchecked {
                v = 27 + uint8(uint256(vs) >> 255);
            }
        } else {
            revert ERC4494__InvalidSignature(address(0));
        }

        address owner = IERC721(address(this)).ownerOf(tokenId);

        unchecked {
            uint256 nonce = nonces[tokenId]++;
            bytes32 digest = EIP712.hashMessage(
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, spender, tokenId, nonce, deadline))
            );

            address recovered = ecrecover(digest, v, r, s);

            bool invalid = recovered == address(0) || !_isApprovedOrOwner(recovered, tokenId);

            if (spender.code.length != 0) {
                if (!verify(spender, digest, v, r, s) || invalid) revert ERC4494__InvalidSignature(recovered);
            } else if (invalid) {
                revert ERC4494__InvalidSignature(recovered);
            }
        }

        _approve(owner, spender, tokenId);
    }

    function verify(
        address spender,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool success) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let reuse := mload(0x40)
            // Write the abi-encoded calldata to memory piece by piece:
            // EIP 1271 sig
            mstore(reuse, 0x1626ba7e00000000000000000000000000000000000000000000000000000000)
            mstore(add(reuse, 4), digest) // "digest" argument. No mask as it's a full 32 byte value.
            mstore(add(reuse, 36), 0x0000000000000000000000000000000000000000000000000000000000000040)
            mstore(add(reuse, 68), 0x0000000000000000000000000000000000000000000000000000000000000041)
            mstore(add(reuse, 133), and(v, 0xff)) // Finally append the "v" argument. with mask uint8
            mstore(add(reuse, 100), r) // "r" argument. No mask as it's a full 32 byte value.
            mstore(add(reuse, 132), s) // "s" argument. No mask as it's a full 32 byte value.
            // use 101 because the calldata length is 4 + 32 * 5 + 1.
            let callStatus := staticcall(gas(), spender, reuse, 165, 0, 32)
            let returnDataSize := returndatasize()
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }
            // returndata copy
            returndatacopy(reuse, 0, returnDataSize)
            switch mload(reuse)
            case 0x1626ba7e00000000000000000000000000000000000000000000000000000000 {
                success := 1
            }
            case 0xffffffff00000000000000000000000000000000000000000000000000000000 {
                success := 0
            }
            default {
                success := 0
            }
        }
    }
}
