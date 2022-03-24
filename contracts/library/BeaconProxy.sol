/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

/**
 * @title BeaconProxy
 * @author yoonsung.eth
 * @notice A library that helps deploy Beacon proxy,
 * the minimum contract size referring to the implementation through Beacon.
 */
library BeaconProxy {
    /**
     * @notice Deploy BeaconProxy based on beacon contract address.
     * @dev If the seed value is 0x0, it is deploy use "create",
     * but if it is other values, it is deploy use "create2" using seed. If it is the same seed, it will fail.
     * @param beacon    The address of the beacon contract that returns the implementation.
     * @param seed      This value is not 0x0, it is deploy as create2 based on the corresponding seed.
     * @return result   address of deployed contract
     */
    function deploy(address beacon, bytes32 seed) internal returns (address result) {
        (uint256 creationPtr, uint256 creationSize) = creationCode(beacon);
        unchecked {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                if iszero(eq(seed, 0x0)) {
                    result := create2(0, creationPtr, creationSize, seed)
                }

                if eq(seed, 0x0) {
                    result := create(0, creationPtr, creationSize)
                }

                if iszero(extcodesize(result)) {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }

    /**
     * @notice Create a creation code to deploy the BeaconProxy and return the pointer and size.
     * @param beacon        address of beacon contract
     * @return createPtr    position of creation code in memory
     * @return creationSize size of creation code in memory
     */
    function creationCode(address beacon) internal pure returns (uint256 createPtr, uint256 creationSize) {
        unchecked {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                createPtr := mload(0x40)
                creationSize := 0x47
                mstore(createPtr, 0x600b5981380380925939f33d3d3d3d3d73000000000000000000000000000000)
                mstore(add(createPtr, 0x11), shl(0x60, beacon))
                mstore(add(createPtr, 0x25), 0x5afa3d82803e368260203750808036602082515af43d82803e903d91603a57fd)
                mstore(add(createPtr, 0x45), 0x5bf3000000000000000000000000000000000000000000000000000000000000)
            }
        }
    }

    /**
     * @notice Verify that the contract deployed is a beacon contract.
     * @param target    deployed address to verify.
     * @param beacon    for reference to specific beacon contracts.
     * @return result   Beacon contract or not.
     */
    function isBeacon(address target, address beacon) internal view returns (bool result) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d3d3d3d3d730000000000000000000000000000000000000000000000000000)
            mstore(add(clone, 0x6), shl(0x60, beacon))
            mstore(add(clone, 0x1a), 0x5afa3d82803e368260203750808036602082515af43d82803e903d91603a57fd)
            mstore(add(clone, 0x3a), 0x5bf3000000000000000000000000000000000000000000000000000000000000)

            let other := add(clone, 0x40)
            extcodecopy(target, other, 0, 0x3c)
            result := eq(mload(clone), mload(other))
        }
    }

    /**
     * @notice Verify that the contract deployed is a beacon contract.
     * @param target    deployed address to verify.
     * @return result   Beacon contract or not.
     */
    function isBeacon(address target) internal view returns (bool result) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let template := mload(0x40)
            let clone := add(template, 0x40)
            extcodecopy(target, template, 0x6, 0x15)

            mstore(clone, 0x3d3d3d3d3d730000000000000000000000000000000000000000000000000000)
            mstore(add(clone, 0x6), mload(template))
            mstore(add(clone, 0x1a), 0x5afa3d82803e368260203750808036602082515af43d82803e903d91603a57fd)
            mstore(add(clone, 0x3a), 0x5bf3000000000000000000000000000000000000000000000000000000000000)

            let other := add(clone, 0x40)
            extcodecopy(target, other, 0, 0x3c)
            result := eq(mload(clone), mload(other))
        }
    }

    /**
     * @notice Before you deploy the beacon proxy to create2, you can identify the address.
     * @param beacon    address for reference to deployed beacon contracts.
     * @param seed      bytes32 for create2 salt
     * @return target   Specifed deployable address
     */
    function computeAddress(address beacon, bytes32 seed) internal view returns (address target) {
        (uint256 creationPtr, uint256 creationSize) = creationCode(beacon);
        bytes32 creationHash;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            creationHash := keccak256(creationPtr, creationSize)
        }

        target = address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), seed, creationHash))))
        );
    }

    /**
     * @notice Use a specific beacon contract to search for address and seed that can be deploy to create2.
     * @param beacon    address for reference to deployed beacon contracts.
     * @return seed     deployable create2 salt
     * @return target   Specifed deployable address
     */
    function seedSearch(address beacon) internal view returns (bytes32 seed, address target) {
        (uint256 creationPtr, uint256 creationSize) = creationCode(beacon);

        bytes32 creationHash;
        uint256 nonce = 0;
        bool exist;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            creationHash := keccak256(creationPtr, creationSize)
        }

        while (true) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(0x80, caller())
                mstore(0xa0, nonce)
                seed := keccak256(0x80, 0xc0)
            }

            target = address(
                uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), seed, creationHash))))
            );

            // solhint-disable-next-line no-inline-assembly
            assembly {
                exist := gt(extcodesize(target), 0)
            }

            if (!exist) {
                break;
            }

            unchecked {
                ++nonce;
            }
        }
    }
}
