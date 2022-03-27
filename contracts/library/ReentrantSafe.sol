/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

error Reentrant();

/**
 * @title ReentrantSafe
 * @author yoonsung.eth
 * @notice Prevent the function from running again while it is running
 * @dev 다양한 Modifier가 포함된 재진입을
 * TODO: after shanghi switch to tload and tstore
 */
abstract contract ReentrantSafe {
    uint256 private ent = 1;

    /**
     * @notice 해당 modifier가 적용된 함수는 재진입이 불가능하여, 시도되는 경우 revert 됩니다
     * @dev 해당 safer는 실패 메시지를 반환하지 않습니다
     * @dev 이것이 다양한 modifier와 함께 사용될 때 가장 왼쪽에 위치하는 것이 일반적인 사용입니다.
     */
    modifier reentrantSafer() {
        if(ent != 1) revert Reentrant();

        ent = 2;

        _;

        ent = 1;
    }

    /**
     * @notice 해당 modifier가 적용된 함수는 재진입이 불가능하여, 시도되는 경우 revert 됩니다
     * @dev 해당 safer는 실패 메시지를 반환하지 않습니다
     * @dev 이것이 다양한 modifier와 함께 사용될 때 가장 왼쪽에 위치하여야 하며,
     * 가장 오른쪽에 `reentrantEnd`가 같이 사용되어 다른 modifier를 감싸는 형태가 되어야 합니다.
     */
    modifier reentrantStart() {
        if(ent != 1) revert Reentrant();

        ent = 2;

        _;
    }

    /**
     * @notice 해당 modifier가 적용된 함수는 재진입이 불가능하여, 시도되는 경우 revert 됩니다
     * @dev 해당 safer는 실패 메시지를 반환하지 않습니다
     * @dev 이것이 다양한 modifier와 함께 사용될 때 가장 오른쪽에 위치하여야 하며,
     * 가장 왼쪽에 `reentrantStart`가 같이 사용되어 다른 modifier를 감싸는 형태가 되어야 합니다.
     */
    modifier reentrantEnd() {
        _;

        ent = 1;
    }
}
