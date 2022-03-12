/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

/**
 * @title MinimalProxy
 * @author yoonsung.eth
 * @notice Minimal Proxy를 배포하는 기능을 가지고 있습니다.
 */
library MinimalProxy {
    /**
     * @notice template를 기반으로 Minimal Proxy를 배포합니다.
     * @dev seed 값이 0x0이라면 create로 배포되지만, 그 외의 값인 경우 seed를 이용하여 create2로 배포됩니다. 만약 같은 seed라면, 
     * @param template 복사할 컨트랙트 주소
     * @param seed 해당 값을 기반으로 create2로 배포됩니다.
     */
    function deploy(address template, bytes32 seed) internal returns (address result) {
        (uint256 creationPtr, uint256 creationSize) = creationCode(template);
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
     * @notice Minimal Proxy를 배포할 creation code를 생성하여 포인터와 크기를 반환합니다.
     * @param template Minimal Proxy로 배포할 컨트랙트 주소
     * @return createPtr position of creation code in memory
     * @return creationSize size of creation code in memory
     */
    function creationCode(address template) internal pure returns (uint256 createPtr, uint256 creationSize) {
        unchecked {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                createPtr := mload(0x40)
                creationSize := 0x38
                mstore(createPtr, 0x600b5981380380925939f3363d3d373d3d3d363d730000000000000000000000)
                mstore(add(createPtr, 0x15), shl(0x60, template))
                mstore(add(createPtr, 0x29), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            }
        }
    }

    function isMinimal(address template, address target) internal view returns (bool result) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
            mstore(add(clone, 0xa), shl(0x60, template))
            mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

            let other := add(clone, 0x40)
            extcodecopy(target, other, 0, 0x2d)
            result := eq(mload(clone), mload(other))
        }
    }

    function computeAddress(address template, bytes32 seed) internal view returns (address target) {
        (uint256 creationPtr, uint256 creationSize) = creationCode(template);
        bytes32 creationHash;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            creationHash := keccak256(creationPtr, creationSize)
        }

        target = address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), seed, creationHash))))
        );
    }

    function seedSearch(address template) internal view returns (bytes32 seed, address target) {
        (uint256 creationPtr, uint256 creationSize) = creationCode(template);

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
                mstore(0x0, caller())
                mstore(0x20, nonce)
                seed := keccak256(0x00, 0x40)
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
