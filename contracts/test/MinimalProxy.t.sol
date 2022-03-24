/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "../library/MinimalProxy.sol";

interface CheatCodes {
    function expectRevert(bytes calldata) external;
}

interface IDummy {
    function name() external returns (string memory);
}

interface IDestruct {
    function destruct() external;
}

contract DummyTemplate is IDummy {
    string public name = "bean the DAO on the Blocks";

    function initialize(string memory _name) external returns (bool) {
        name = _name;
        return true;
    }
}

contract DestructTemplate is IDummy, IDestruct {
    string public name = "bean the DAO on the Blocks";

    function destruct() external {
        selfdestruct(payable(msg.sender));
    }
}

contract RevertDummyMock is IDummy {
    string public name = "bean the DAO on the Blocks";

    function initialize(string memory _name) external returns (bool) {
        name = _name;
        revert("Intentional REVERT");
    }
}

contract MinimalProxyTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    function testComputeCreate2Check() public {
        address template = address(new DummyTemplate());
        address deployable = MinimalProxy.computeAddress(
            template,
            0x1000000000f00000000000000000000f00000000000000000f0000000000000f
        );
        address DummyProxy = MinimalProxy.deploy(
            template,
            0x1000000000f00000000000000000000f00000000000000000f0000000000000f
        );
        assertEq(DummyProxy, deployable);
    }

    function testIsMinimalWithoutTemplate() public {
        address template = address(new DummyTemplate());
        address DummyProxy = MinimalProxy.deploy(
            template,
            0x1000000000f00000000000000000000f00000000000000000f0000000000000f
        );
        assertTrue(MinimalProxy.isMinimal(DummyProxy));
    }

    function testIsMinimalWithTemplate() public {
        address template = address(new DummyTemplate());
        address DummyProxy = MinimalProxy.deploy(
            template,
            0x1000000000f00000000000000000000f00000000000000000f0000000000000f
        );
        assertTrue(MinimalProxy.isMinimal(DummyProxy, template));
    }

    function testIncrementDeploy() public {
        address template = address(new DummyTemplate());

        (bytes32 seed, address addr) = MinimalProxy.seedSearch(template);
        for (uint256 i; i != 10; ) {
            bytes32 prevSeed = seed;
            address prevAddr = addr;
            address DummyProxy = MinimalProxy.deploy(template, seed);
            (seed, addr) = MinimalProxy.seedSearch(template);
            assertTrue(seed != prevSeed);
            assertTrue(DummyProxy == prevAddr);
            assertTrue(addr != DummyProxy);
            unchecked {
                ++i;
            }
        }
    }

    function testFailReDeployDestructPoint() public {
        address template = address(new DestructTemplate());
        (bytes32 seed, ) = MinimalProxy.seedSearch(template);

        address deployable = MinimalProxy.computeAddress(template, seed);
        address DestructProxy = MinimalProxy.deploy(template, seed);
        IDestruct(DestructProxy).destruct();
        assertEq(DestructProxy.code.length, 0);
        DestructProxy = MinimalProxy.deploy(template, seed);
        assertEq(DestructProxy, deployable);
    }

    function testCallCode() public {
        address DummyProxy = MinimalProxy.deploy(address(new DummyTemplate()), "");

        bytes memory callCode = abi.encodeWithSelector(bytes4(keccak256("name()")));
        (bool success, bytes memory data) = DummyProxy.call(callCode);
        assertTrue(success);

        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), "Hello World");
        (success, data) = DummyProxy.call(initCode);
        assertTrue(success);
        assertEq(bytes32(data), 0x0000000000000000000000000000000000000000000000000000000000000001);
        assertEq(IDummy(DummyProxy).name(), "Hello World");
    }

    function testCallCodeToRevert() public {
        address RevertProxy = MinimalProxy.deploy(address(new RevertDummyMock()), "");
        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), "Hello World");
        cheats.expectRevert("Intentional REVERT");
        (bool success, ) = RevertProxy.call(initCode);
        assertTrue(success);
        assertEq(IDummy(RevertProxy).name(), "");
    }
}
