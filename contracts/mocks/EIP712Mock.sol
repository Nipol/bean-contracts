/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.0;

import "../library/EIP712.sol";
import "hardhat/console.sol";

error InvalidSignature(address recovered);

contract EIP712Mock {
    struct Value {
        uint256 value;
    }

    struct Receiver {
        uint256[] value;
    }

    struct Receive {
        address[] receivers;
        uint256[] values;
    }

    string public constant name = "EIP712Mock";
    string public constant version = "1";
    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public constant VERIFY_PLAIN_TYPEHASH = keccak256("Verify(address owner,uint256 value,uint256 nonce)");
    bytes32 public constant VERIFY_ARRAY_TYPEHASH = keccak256("Verify(address owner,uint256[] values,uint256 nonce)");

    bytes32 public constant VALUE_TYPEHASH = keccak256("Value(uint256 value)");
    // Custom Types used must be located at the end.
    bytes32 public constant VERIFY_COMPLEX_TYPEHASH =
        keccak256("Verify(address owner,Value value,uint256 nonce)Value(uint256 value)");

    bytes32 public constant RECEIVER_TYPEHASH = keccak256("Receiver(uint256[] value)");
    bytes32 public constant VERIFY_VERYCOMPLEX_TYPEHASH =
        keccak256("Verify(address owner,Receiver value,uint256 nonce)Receiver(uint256[] value)");

    bytes32 public constant RECEIVE_TYPEHASH = keccak256("Receive(address[] receivers,uint256[] values)");
    bytes32 public constant VERIFY_VERYVERYCOMPLEX_TYPEHASH =
        keccak256("Verify(address owner,Receive value,uint256 nonce)Receive(address[] receivers,uint256[] values)");

    mapping(address => uint256) public nonces;

    constructor(bytes32 salt) {
        DOMAIN_SEPARATOR = salt == bytes32(0)
            ? EIP712.hashDomainSeperator(name, version, address(this))
            : EIP712.hashDomainSeperator(name, version, address(this), salt);
    }

    function verify(
        address owner,
        uint256 value,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        uint256 nonce = nonces[owner]++;
        bytes32 digest = EIP712.hashMessage(
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(VERIFY_PLAIN_TYPEHASH, owner, value, nonce))
        );

        address recovered = ecrecover(digest, v, r, s);
        if (recovered == address(0) || recovered != owner) revert InvalidSignature(recovered);
    }

    function verify(
        address owner,
        uint256[] calldata values,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        uint256 nonce = nonces[owner]++;
        bytes32 digest = EIP712.hashMessage(
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(VERIFY_ARRAY_TYPEHASH, owner, keccak256(abi.encodePacked(values)), nonce))
        );

        address recovered = ecrecover(digest, v, r, s);
        if (recovered == address(0) || recovered != owner) revert InvalidSignature(recovered);
    }

    function verify(
        address owner,
        Value calldata va,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        uint256 nonce = nonces[owner]++;
        bytes32 digest = EIP712.hashMessage(
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(VERIFY_COMPLEX_TYPEHASH, owner, hashStruct(va), nonce))
        );

        address recovered = ecrecover(digest, v, r, s);
        if (recovered == address(0) || recovered != owner) revert InvalidSignature(recovered);
    }

    function hashStruct(Value calldata value) public pure returns (bytes32) {
        return keccak256(abi.encode(VALUE_TYPEHASH, value.value));
    }

    function verify(
        address owner,
        Receiver calldata va,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        uint256 nonce = nonces[owner]++;
        bytes32 digest = EIP712.hashMessage(
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(VERIFY_VERYCOMPLEX_TYPEHASH, owner, hashStruct(va), nonce))
        );

        address recovered = ecrecover(digest, v, r, s);
        if (recovered == address(0) || recovered != owner) revert InvalidSignature(recovered);
    }

    function hashStruct(Receiver calldata value) public pure returns (bytes32) {
        return keccak256(abi.encode(RECEIVER_TYPEHASH, keccak256(abi.encodePacked(value.value))));
    }

    function verify(
        address owner,
        Receive calldata va,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        uint256 nonce = nonces[owner]++;
        bytes32 digest = EIP712.hashMessage(
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(VERIFY_VERYVERYCOMPLEX_TYPEHASH, owner, hashStruct(va), nonce))
        );

        address recovered = ecrecover(digest, v, r, s);
        if (recovered == address(0) || recovered != owner) revert InvalidSignature(recovered);
    }

    function hashStruct(Receive calldata value) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    RECEIVE_TYPEHASH,
                    keccak256(abi.encodePacked(value.receivers)),
                    keccak256(abi.encodePacked(value.values))
                )
            );
    }
}
