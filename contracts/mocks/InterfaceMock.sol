/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */
pragma solidity ^0.8.0;

import "../interfaces/IERC165.sol";
import "../interfaces/IERC173.sol";

contract InterfaceMock is IERC165, IERC173 {
    event Dummy();

    function owner() external pure returns (address) {
        return address(0);
    }

    function transferOwnership(address) external {
        emit Dummy();
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == type(IERC173).interfaceId || interfaceID == type(IERC165).interfaceId;
    }
}
