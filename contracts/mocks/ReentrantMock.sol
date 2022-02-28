/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "../library/ReentrantSafe.sol";

interface IMock {
    function increaseFunc() external;

    function decreaseFunc() external;
}

interface IEncounterCaller {
    function onEncounter() external;
}

contract EncounterCaller is IEncounterCaller {
    IMock Encounter;

    constructor(address EncounterAddr) {
        Encounter = IMock(EncounterAddr);
    }

    function increase() external {
        Encounter.increaseFunc();
    }

    function onEncounter() external {
        Encounter.decreaseFunc();
    }
}

contract ReentrantCorrectMock is IMock, ReentrantSafe {
    uint256 public encounter;

    constructor(uint256 initial) {
        encounter = initial;
    }

    modifier increase() {
        encounter++;
        _;
    }

    modifier decrease() {
        encounter--;
        _;
    }

    function increaseFunc() external reentrantStart increase reentrantEnd {
        if (msg.sender.code.length != 0) IEncounterCaller(msg.sender).onEncounter();
    }

    function decreaseFunc() external reentrantStart decrease reentrantEnd {
        if (msg.sender.code.length != 0) IEncounterCaller(msg.sender).onEncounter();
    }
}

contract ReentrantInorrectMock is IMock, ReentrantSafe {
    uint256 public encounter;

    constructor(uint256 initial) {
        encounter = initial;
    }

    modifier increase() {
        encounter++;
        _;
    }

    modifier decrease() {
        encounter--;
        _;
    }

    function increaseFunc() external reentrantEnd increase reentrantStart {
        if (msg.sender.code.length != 0) IEncounterCaller(msg.sender).onEncounter();
    }

    function decreaseFunc() external reentrantEnd increase reentrantStart {
        if (msg.sender.code.length != 0) IEncounterCaller(msg.sender).onEncounter();
    }
}
