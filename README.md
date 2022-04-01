# bean the DAO Contract library

Helpful library for solidity.


## Installation

```shell
npm install -d @beandao/contracts
```

## Usage
Copy the code below, paste it into [Remix](https://remix.ethereum.org), deploy it, and test it. Remix automatically gets the @beandao library from npm.

```solidity
pragma solidity ^0.8.0;

import "@beandao/contracts/interfaces/IERC165.sol";
import {ERC20, IERC20} from "@beandao/contracts/library/ERC20.sol";
import {ERC2612, IERC2612} from "@beandao/contracts/library/ERC2612.sol";
import {Ownership, IERC173} from "@beandao/contracts/library/Ownership.sol";
import {Multicall, IMulticall} from "@beandao/contracts/library/Multicall.sol";

contract TokenMock is ERC20, ERC2612, Ownership, Multicall, IERC165 {
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals,
        string memory tokenVersion,
        uint256 balance
    ) {
        _initDomainSeparator(tokenName, '1');
        name = tokenName;
        symbol = tokenSymbol;
        decimals = tokenDecimals;
        balanceOf[msg.sender] = balance;
        totalSupply = balance;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            // ERC20
            interfaceId == type(IERC20).interfaceId ||
            // ERC173
            interfaceId == type(IERC173).interfaceId ||
            // ERC2612
            interfaceId == type(IERC2612).interfaceId;
    }
}
```


## included
**Abstract Contract**
* Aggregatecall - The contract using this library is set the caller to this contract and calls are execute in order.
* Multicall - This library allows to execute functions specified in the contract in order.
* ERC20 - Standard ERC20 specification implementation
* ERC721 - Standard ERC721 and ERC721Metadata specification implementation
* ERC721Enumerable - Standard ERC721Enumerable and ERC721Metadata specification implementation
* ERC2612 - Provide EIP2612 details aka permit for ERC20 and smooth the approach process by signing
* ERC4494 - Provide EIP4494 details aka permit for ERC721 and smooth the approach process by signing
* Initializer - After the contract is deployed, you can configure a function that can only be called once
* Ownership - It is a single contract ownership and follows the ERC173 specification
* PermissionTable - Manage the contract address and its callable function signatures as an allow list. It can be managed with up to 256 Roles.
* ReentrantSafe - Prevent the function from running again while it is running
* Scheduler - Manage task-level scheduling at the time specified by the developer
* Wizadry - Many Tx's can be compressed into one, and execution can be dynamically changed depending on the running state.

**Library Contract**
* BeaconDeployer - This is a wrapper that deploy beacon contracts created in yul.
* BeaconProxy - A library that helps deploy Beacon proxy the minimum contract size referring to the implementation through Beacon.
* MinimalProxy - It helps to deploy the Minimal Proxy, which is the EIP 1167 specification.
* EIP712 - Easy set of functions to support EIP712, signTypedData specifications
* Witchcraft - A library for magical dynamic ABIs


## Acknowledgements

These contracts were inspired by or directly modified from many sources, primarily:


- [Uniswap](https://github.com/Uniswap/uniswap-lib)
- [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [Optionality](https://github.com/optionality/clone-factory)
- [Spawner](https://github.com/0age/Spawner)
- [Weiroll](https://github.com/weiroll/weiroll)
