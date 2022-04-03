/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import {ERC20, IERC20} from "./ERC20.sol";
import {ERC2612, IERC2612} from "./ERC2612.sol";
import "../interfaces/IERC165.sol";

contract WETH is ERC20("Wrapped Ether", "WETH", 18), ERC2612("Wrapped Ether", "1"), IERC165 {
    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        totalSupply += msg.value;
        unchecked {
            balanceOf[msg.sender] += msg.value;
        }

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        balanceOf[msg.sender] -= amount;
        unchecked {
            totalSupply -= amount;
        }

        address to = msg.sender;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let callStatus := call(gas(), to, amount, 0, 0, 0, 0)
            if iszero(callStatus) {
                let returnDataSize := returndatasize()
                returndatacopy(0, 0, returnDataSize)
                revert(0, returnDataSize)
            }
        }
        emit Withdrawal(msg.sender, amount);
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool support) {
        support =
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IERC2612).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
