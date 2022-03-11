/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

uint256 constant ELEMENT_POS_MASK = 0x3f;
uint256 constant IO_END_OF_ARGS = 0xff;
uint256 constant IO_USE_ELEMENTS = 0xfe;
uint256 constant IO_USE_DYNAMIC = 0xC0;
uint256 constant IO_USE_ENCODE = 0x80;
uint256 constant IO_USE_PACK = 0x40;
uint256 constant IO_USE_STATIC = 0x00;
uint256 constant IO_USE_MASK = 0xC0;

/**
 * @title Witchcraft
 * @author yoonsung.eth
 * @notice
 * - 이 전체 값은 기본적으로 elements의 배열에 접근하기 위한 정보로 사용된다.
 *   대체로 0~127 사이의 값이며, 0xff라면 해당 인덱스에 접근하지 않는다.
 *   다만 첫 bit 값이 0이라면, Pos의 값에 따라 elements에 접근하고
 */

library Witchcraft {
    /**
     * @notice elements에서, indices의
     * @param elements 배열,
     * @param indices elements에 접근할 정보를 가지고 있는 슬롯의 모음.
     */
    function extract(bytes[] memory elements, bytes32 indices) internal pure returns (uint256 value) {
        bytes memory v = elements[uint8(bytes1(indices)) & ELEMENT_POS_MASK];
        // solhint-disable-next-line no-inline-assembly
        assembly {
            value := mload(add(v, 0x20))
        }
    }

    function toSpell(
        bytes[] memory elements,
        bytes4 selector,
        bytes32 indices
    ) internal view returns (bytes memory ret) {
        (uint256 count, uint256 free) = (0, 0); // 인코딩 된 바이트 수
        bytes memory paramData; // option, 호출이 필요로 하는 경우 현재 상태 인코딩에 사용
        uint8 idx;

        for (uint256 i; i != 32; ) {
            idx = uint8(indices[i]);
            if (idx == IO_END_OF_ARGS) break;

            if (idx == IO_USE_ELEMENTS) {
                // 0xfe, 모든 elements를 연속된 인자로 사용한다.
                // 총 길이가 32bytes가 되지 않더라도, free pointer가 이후에 작성되기 때문에 32byte로 떨어짐
                if (paramData.length == 0) {
                    paramData = abi.encode(elements);
                }
                unchecked {
                    count += paramData.length;
                    free += 32;
                }
            } else if (idx & IO_USE_MASK == IO_USE_DYNAMIC) {
                // 0xC0, 특정 element를 하나의 인자로 사용한다.
                // 총 길이가 32bytes가 되지 않더라도, free pointer가 이후에 작성되기 때문에 32byte로 떨어짐
                uint256 arglen = elements[idx & ELEMENT_POS_MASK].length;
                assert(arglen % 32 == 0);
                unchecked {
                    count += arglen + 32; // 데이터 포지션 기록때문에 32 padding
                    free += 32;
                }
            } else if (idx & IO_USE_MASK == IO_USE_ENCODE) {
                // 0x80, 현재 인덱스의 인자에 대해 32bytes mod zero-padding, 길이 삽입, 데이터 위치 지정 을 수행한다.
                // 마스킹 되어서 배열로 들어온 포지션
                paramData = abi.encode(elements[idx & ELEMENT_POS_MASK]);
                unchecked {
                    count += paramData.length;
                    free += 32;
                }
            } else if (idx & IO_USE_MASK == IO_USE_PACK) {
                // 0x40, 현재의 인자를 패킹만 함.
                paramData = abi.encodePacked(elements[idx & ELEMENT_POS_MASK]);
                unchecked {
                    count += paramData.length - 32;
                    free += 32;
                }
            } else if (idx & IO_USE_MASK == IO_USE_STATIC) {
                // 0x00,
                assert(elements[idx & ELEMENT_POS_MASK].length == 32);
                unchecked {
                    count += 32;
                    free += 32;
                }
            }

            unchecked {
                i++;
            }
        }

        unchecked {
            ret = new bytes(count + 4);
        }
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(add(ret, 32), selector)
        }
        count = 0;

        for (uint256 i; i != 32; ) {
            idx = uint8(indices[i]);
            if (idx == IO_END_OF_ARGS) break;

            if (idx == IO_USE_ELEMENTS) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    mstore(add(add(ret, 36), count), free)
                }
                unchecked {
                    memcpy(paramData, 32, ret, free + 4, paramData.length - 32);
                    free += paramData.length - 32;
                    count += 32;
                }
            } else if (idx & IO_USE_MASK == IO_USE_DYNAMIC) {
                uint256 arglen = elements[idx & ELEMENT_POS_MASK].length;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    mstore(add(add(ret, 36), count), free)
                }
                unchecked {
                    memcpy(elements[idx & ELEMENT_POS_MASK], 0, ret, free + 4, arglen);
                    free += arglen;
                    count += 32;
                }
            } else if (idx & IO_USE_MASK == IO_USE_ENCODE) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    mstore(add(add(ret, 36), count), free)
                }
                unchecked {
                    memcpy(paramData, 32, ret, free + 4, paramData.length);
                    free += paramData.length - 32;
                    count += 32;
                }
            } else if (idx & IO_USE_MASK == IO_USE_PACK) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    mstore(add(add(ret, 36), count), count)
                }
                unchecked {
                    memcpy(paramData, 32, ret, count + 4, paramData.length);
                    count += paramData.length - 32;
                    free += 32;
                }
            } else if (idx & IO_USE_MASK == IO_USE_STATIC) {
                bytes memory element = elements[idx & ELEMENT_POS_MASK];
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    mstore(add(add(ret, 36), count), mload(add(element, 32)))
                }
                unchecked {
                    count += 32;
                }
            }

            unchecked {
                i++;
            }
        }
    }

    // TODO: 아무 것도 반환하지 않는 함수인데, 포지션을 지정하면 길이가 맞지 않아서 방법이 필요함
    function writeOutputs(
        bytes[] memory elements,
        bytes1 index,
        bytes memory output
    ) internal pure returns (bytes[] memory newEle) {
        uint256 idx = uint8(index);
        if (idx == IO_END_OF_ARGS) return elements;

        if (idx == IO_USE_ELEMENTS) {
            elements = abi.decode(output, (bytes[]));
        } else if (idx & IO_USE_MASK == IO_USE_DYNAMIC) {
            // Check the first field is 0x20 (because we have only a single return value)
            uint256 argptr;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                argptr := mload(add(output, 32))
            }
            assert(argptr == 32);

            // solhint-disable-next-line no-inline-assembly
            assembly {
                // Overwrite the first word of the return data with the length - 32
                mstore(add(output, 32), sub(mload(output), 32))
                // Insert a pointer to the return data, starting at the second word, into state
                mstore(add(add(elements, 32), mul(and(idx, ELEMENT_POS_MASK), 32)), add(output, 32))
            }
        } else if (idx & IO_USE_MASK == IO_USE_ENCODE) {
            elements[idx & ELEMENT_POS_MASK] = abi.decode(output, (bytes));
        } else if (idx & IO_USE_MASK == IO_USE_PACK) {
            // 앞의 데이터 포인터, 및 데이터 길이를 지운다음 데이터만 남긴다.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(add(add(elements, 32), mul(and(idx, ELEMENT_POS_MASK), 32)), add(output, 64))
            }
        } else {
            // Single word
            assert(output.length == 32);
            elements[idx & ELEMENT_POS_MASK] = output;
        }

        return elements;
    }

    function writeTuple(
        bytes[] memory elements,
        bytes1 index,
        bytes memory output
    ) internal view {
        uint8 idx = uint8(index);
        if (idx == IO_END_OF_ARGS) return;

        unchecked {
            bytes memory entry = elements[idx] = new bytes(output.length + 32);
            memcpy(output, 0, entry, 32, output.length);
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let l := mload(output)
                mstore(add(entry, 32), l)
            }
        }
    }

    function memcpy(
        bytes memory src,
        uint256 srcidx,
        bytes memory dest,
        uint256 destidx,
        uint256 len
    ) internal view {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            pop(staticcall(gas(), 4, add(add(src, 32), srcidx), len, add(add(dest, 32), destidx), len))
        }
    }
}
