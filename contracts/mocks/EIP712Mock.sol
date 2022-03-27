/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.0;

import "../library/EIP712.sol";
import "hardhat/console.sol";

error InvalidSignature(address recovered);

contract EIP712Mock {
    bytes32 internal constant EIP712DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

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

    struct Person {
        string name;
        address[] wallets;
    }

    struct Mail {
        Person from;
        Person[] to;
        string contents;
    }

    string public constant name = "EIP712Mock";
    string public constant version = "1";
    bytes32 public immutable DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    constructor(bytes32 salt) {
        DOMAIN_SEPARATOR = salt == bytes32(0)
            ? EIP712.hashDomainSeperator(name, version, address(this))
            : EIP712.hashDomainSeperator(name, version, address(this), salt);
    }

    bytes32 public constant VERIFY_PLAIN_TYPEHASH = keccak256("Verify(address owner,uint256 value,uint256 nonce)");

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

    bytes32 public constant VERIFY_ARRAY_TYPEHASH = keccak256("Verify(address owner,uint256[] values,uint256 nonce)");

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

    bytes32 public constant VALUE_TYPEHASH = keccak256("Value(uint256 value)");
    // Custom Types used must be located at the end.
    bytes32 public constant VERIFY_STRUCT_TYPEHASH =
        keccak256("Verify(address owner,Value value,uint256 nonce)Value(uint256 value)");

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
            keccak256(abi.encode(VERIFY_STRUCT_TYPEHASH, owner, hashStruct(va), nonce))
        );

        address recovered = ecrecover(digest, v, r, s);
        if (recovered == address(0) || recovered != owner) revert InvalidSignature(recovered);
    }

    function hashStruct(Value calldata value) public pure returns (bytes32) {
        return keccak256(abi.encode(VALUE_TYPEHASH, value.value));
    }

    bytes32 public constant RECEIVER_TYPEHASH = keccak256("Receiver(uint256[] value)");
    bytes32 public constant VERIFY_STRUCT_ARRAY_TYPEHASH =
        keccak256("Verify(address owner,Receiver value,uint256 nonce)Receiver(uint256[] value)");

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
            keccak256(abi.encode(VERIFY_STRUCT_ARRAY_TYPEHASH, owner, hashStruct(va), nonce))
        );

        address recovered = ecrecover(digest, v, r, s);
        if (recovered == address(0) || recovered != owner) revert InvalidSignature(recovered);
    }

    function hashStruct(Receiver calldata value) public pure returns (bytes32) {
        return keccak256(abi.encode(RECEIVER_TYPEHASH, keccak256(abi.encodePacked(value.value))));
    }

    bytes32 public constant RECEIVE_TYPEHASH = keccak256("Receive(address[] receivers,uint256[] values)");
    bytes32 public constant VERIFY_STRUCT_DOUBLE_ARRAY_TYPEHASH =
        keccak256("Verify(address owner,Receive value,uint256 nonce)Receive(address[] receivers,uint256[] values)");

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
            keccak256(abi.encode(VERIFY_STRUCT_DOUBLE_ARRAY_TYPEHASH, owner, hashStruct(va), nonce))
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

    bytes32 public constant PERSON_TYPEHASH = keccak256("Person(string name,address[] wallets)");
    bytes32 public constant MAIL_TYPEHASH =
        keccak256("Mail(Person from,Person[] to,string contents)Person(string name,address[] wallets)");
    bytes32 public constant VERIFY_MAIL_TYPEHASH =
        keccak256(
            "Verify(address owner,Mail mail,uint256 nonce)Mail(Person from,Person[] to,string contents)Person(string name,address[] wallets)"
        );

    function verify(
        address owner,
        Mail calldata va,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        uint256 nonce = nonces[owner]++;
        bytes32 digest = EIP712.hashMessage(
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(VERIFY_MAIL_TYPEHASH, owner, hashStruct(va), nonce))
        );

        address recovered = ecrecover(digest, v, r, s);
        if (recovered == address(0) || recovered != owner) revert InvalidSignature(recovered);
    }

    function hashStruct(Mail calldata value) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MAIL_TYPEHASH,
                    hashStruct(value.from),
                    hashStruct(value.to),
                    keccak256(bytes(value.contents))
                )
            );
    }

    function hashStruct(Person[] calldata values) public pure returns (bytes32) {
        uint256 length = values.length;
        bytes32[] memory encode = new bytes32[](length);
        for (uint256 i; i != length; ) {
            encode[i] = hashStruct(values[i]);
            unchecked {
                ++i;
            }
        }

        return keccak256(abi.encodePacked(encode));
    }

    function hashStruct(Person calldata value) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(PERSON_TYPEHASH, keccak256(bytes(value.name)), keccak256(abi.encodePacked(value.wallets)))
            );
    }
}
