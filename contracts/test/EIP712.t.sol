/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../library/EIP712.sol";

contract EIP712Test is Test {
    bytes32 public constant VERIFY_PLAIN_TYPEHASH = keccak256("Verify(address owner,uint256 value)");
    bytes32 public constant VERIFY_ARRAY_TYPEHASH = keccak256("Verify(address owner,uint256[] value)");
    bytes32 public constant VERIFY_COMPLEX_TYPEHASH =
        keccak256("Verify(address owner,Value value)Value(uint256[] value)");
    bytes32 public constant VALUE_TYPEHASH = keccak256("Value(uint256[] value)");
    bytes32 public constant VERIFY_VERYCOMPLEX_TYPEHASH =
        keccak256("Verify(address owner,Receiver value)Receiver(address[] owner, uint256[] value)");
    bytes32 public constant RECEIVER_TYPEHASH = keccak256("Receiver(address[] owner, uint256[] value)");

    string public name = "EIP712 Test";
    string public version = "3";
    bytes32 internal DOMAIN_SEPARATOR;
    bytes32 internal VERIFY_PLAIN_DIGEST;
    bytes32 internal VERIFY_ARRAY_DIGEST;
    bytes32 internal VERIFY_COMPLEX_DIGEST;
    bytes32 internal VERIFY_VERYCOMPLEX_DIGEST;

    function setUp() public {
        bytes32 typehash = EIP712.EIP712DOMAIN_TYPEHASH;
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        DOMAIN_SEPARATOR = keccak256(abi.encode(typehash, hashedName, hashedVersion, block.chainid, address(this)));

        VERIFY_PLAIN_DIGEST = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(VERIFY_PLAIN_TYPEHASH, address(this), 1 ether))
            )
        );

        VERIFY_ARRAY_DIGEST = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(VERIFY_ARRAY_TYPEHASH, address(this), keccak256(abi.encodePacked([1 ether, 1 ether])))
                )
            )
        );

        VERIFY_COMPLEX_DIGEST = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        VERIFY_COMPLEX_TYPEHASH,
                        address(this),
                        keccak256(abi.encode(VALUE_TYPEHASH, [1 ether, 1 ether]))
                    )
                )
            )
        );

        VERIFY_VERYCOMPLEX_DIGEST = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        VERIFY_VERYCOMPLEX_TYPEHASH,
                        address(this),
                        keccak256(
                            abi.encode(
                                RECEIVER_TYPEHASH,
                                keccak256(abi.encodePacked([address(this), address(this)])),
                                keccak256(abi.encodePacked([1 ether, 1 ether]))
                            )
                        )
                    )
                )
            )
        );
    }

    function testMakeDomainSeperator() public {
        bytes32 domainHash = EIP712.hashDomainSeperator(name, version, address(this));
        assertEq(domainHash, DOMAIN_SEPARATOR);
    }

    function testPlainHashMessage() public {
        bytes32 digest = EIP712.hashMessage(
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(VERIFY_PLAIN_TYPEHASH, address(this), 1 ether))
        );
        assertEq(digest, VERIFY_PLAIN_DIGEST);
    }

    function testArrayHashMessage() public {
        bytes32 digest = EIP712.hashMessage(
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(VERIFY_ARRAY_TYPEHASH, address(this), keccak256(abi.encodePacked([1 ether, 1 ether]))))
        );
        assertEq(digest, VERIFY_ARRAY_DIGEST);
    }

    function testComplexHashMessage() public {
        bytes32 digest = EIP712.hashMessage(
            DOMAIN_SEPARATOR,
            keccak256(
                abi.encode(
                    VERIFY_COMPLEX_TYPEHASH,
                    address(this),
                    keccak256(abi.encode(VALUE_TYPEHASH, [1 ether, 1 ether]))
                )
            )
        );
        assertEq(digest, VERIFY_COMPLEX_DIGEST);
    }

    function testVeryComplexHashMessage() public {
        bytes32 digest = EIP712.hashMessage(
            DOMAIN_SEPARATOR,
            keccak256(
                abi.encode(
                    VERIFY_VERYCOMPLEX_TYPEHASH,
                    address(this),
                    keccak256(
                        abi.encode(
                            RECEIVER_TYPEHASH,
                            keccak256(abi.encodePacked([address(this), address(this)])),
                            keccak256(abi.encodePacked([1 ether, 1 ether]))
                        )
                    )
                )
            )
        );
        assertEq(digest, VERIFY_VERYCOMPLEX_DIGEST);
    }
}
