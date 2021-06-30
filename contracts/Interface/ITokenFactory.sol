/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

interface ITokenFactory {
    struct TemplateInfo {
        address template;
        uint256 price;
    }

    event SetTemplate(
        bytes32 indexed key,
        address indexed template,
        uint256 indexed price
    );

    event RemovedTemplate(bytes32 indexed key);

    event GeneratedToken(address owner, address token);

    function newTemplate(address template, uint256 price)
        external
        returns (bytes32 key);

    function updateTemplate(
        bytes32 key,
        address template,
        uint256 price
    ) external;

    function deleteTemplate(bytes32 key) external;

    function newToken(
        bytes32 key,
        string memory version,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external returns (address result);

    function newTokenWithMint(
        bytes32 key,
        string memory version,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 amount
    ) external returns (address result);

    function calculateNewTokenAddress(
        bytes32 key,
        string memory version,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external view returns (address result);
}
