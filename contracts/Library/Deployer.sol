/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "./Create2Maker.sol";

library Deployer {
    function deploy(address template, bytes memory initializationCalldata)
        internal
        returns (address result)
    {
        bytes memory createCode =
            abi.encodePacked(
                type(Create2Maker).creationCode,
                abi.encode(address(template), initializationCalldata)
            );

        (bytes32 salt, ) = getSaltAndTarget(createCode);

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let encoded_data := add(0x20, createCode) // load initialization code.
            let encoded_size := mload(createCode) // load the init code's length.
            result := create2(
                // call `CREATE2` w/ 4 arguments.
                0, // forward any supplied endowment.
                encoded_data, // pass in initialization code.
                encoded_size, // pass in init code's length.
                salt // pass in the salt value.
            )

            // pass along failure message from failed contract deployment and revert.
            if iszero(result) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function deployWithValue(
        address template,
        bytes memory initializationCalldata
    ) internal returns (address result) {
        bytes memory createCode =
            abi.encodePacked(
                type(Create2Maker).creationCode,
                abi.encode(address(template), initializationCalldata)
            );

        (bytes32 salt, ) = getSaltAndTarget(createCode);

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let encoded_data := add(0x20, createCode) // load initialization code.
            let encoded_size := mload(createCode) // load the init code's length.
            result := create2(
                // call `CREATE2` w/ 4 arguments.
                callvalue(), // forward any supplied endowment.
                encoded_data, // pass in initialization code.
                encoded_size, // pass in init code's length.
                salt // pass in the salt value.
            )

            // pass along failure message from failed contract deployment and revert.
            if iszero(result) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function calculateAddress(
        address template,
        bytes memory initializationCalldata
    ) internal view returns (address addr) {
        bytes memory createCode =
            abi.encodePacked(
                type(Create2Maker).creationCode,
                abi.encode(address(template), initializationCalldata)
            );

        (, addr) = getSaltAndTarget(createCode);
    }

    function getSaltAndTarget(bytes memory initCode)
        internal
        view
        returns (bytes32 salt, address target)
    {
        // get the keccak256 hash of the init code for address derivation.
        bytes32 initCodeHash = keccak256(initCode);

        // set the initial nonce to be provided when constructing the salt.
        uint256 nonce = 0;

        // declare variable for code size of derived address.
        bool exist;

        while (true) {
            // derive `CREATE2` salt using `msg.sender` and nonce.
            salt = keccak256(abi.encodePacked(msg.sender, nonce));

            target = address( // derive the target deployment address.
                uint160( // downcast to match the address type.
                    uint256( // cast to uint to truncate upper digits.
                        keccak256( // compute CREATE2 hash using 4 inputs.
                            abi.encodePacked( // pack all inputs to the hash together.
                                bytes1(0xff), // pass in the control character.
                                address(this), // pass in the address of this contract.
                                salt, // pass in the salt from above.
                                initCodeHash // pass in hash of contract creation code.
                            )
                        )
                    )
                )
            );

            // determine if a contract is already deployed to the target address.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                exist := gt(extcodesize(target), 0)
            }

            // exit the loop if no contract is deployed to the target address.
            if (!exist) {
                break;
            }

            // otherwise, increment the nonce and derive a new salt.
            nonce++;
        }
    }
}
