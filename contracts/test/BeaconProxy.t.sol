/**
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "../library/BeaconDeployer.sol";
import "../library/BeaconProxy.sol";

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

contract BeaconProxyTest is DSTest {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    address DummyBeacon;
    address RevertBeacon;
    address DestructBeacon;

    function setUp() public {
        DummyBeacon = BeaconDeployer.deploy(address(new DummyTemplate()));
        RevertBeacon = BeaconDeployer.deploy(address(new RevertDummyMock()));
        DestructBeacon = BeaconDeployer.deploy(address(new DestructTemplate()));
    }

    function testComputeCreate2Check() public {
        address deployable = BeaconProxy.computeAddress(
            DummyBeacon,
            0x1000000000f00000000000000000000f00000000000000000f0000000000000f
        );
        address DummyProxy = BeaconProxy.deploy(
            DummyBeacon,
            0x1000000000f00000000000000000000f00000000000000000f0000000000000f
        );
        assertEq(DummyProxy, deployable);
    }

    function testIsBeaconWithoutTemplate() public {
        address DummyProxy = BeaconProxy.deploy(DummyBeacon, "");
        assertTrue(BeaconProxy.isBeacon(DummyProxy));
    }

    function testIsBeaconWithTemplate() public {
        address DummyProxy = BeaconProxy.deploy(DummyBeacon, "");
        assertTrue(BeaconProxy.isBeacon(DummyBeacon, DummyProxy));
    }

    function testIncrementDeploy() public {
        (bytes32 seed, address addr) = BeaconProxy.seedSearch(DummyBeacon);
        for (uint256 i; i != 10; ) {
            bytes32 prevSeed = seed;
            address prevAddr = addr;
            address DummyProxy = BeaconProxy.deploy(DummyBeacon, seed);
            (seed, addr) = BeaconProxy.seedSearch(DummyBeacon);
            assertTrue(seed != prevSeed);
            assertTrue(DummyProxy == prevAddr);
            assertTrue(addr != DummyProxy);
            unchecked {
                ++i;
            }
        }
    }

    function testFailReDeployDestructPoint() public {
        (bytes32 seed, ) = BeaconProxy.seedSearch(DummyBeacon);

        address deployable = BeaconProxy.computeAddress(DestructBeacon, seed);
        address DestructProxy = BeaconProxy.deploy(DestructBeacon, seed);
        IDestruct(DestructProxy).destruct();
        assertEq(DestructProxy.code.length, 0);
        DestructProxy = BeaconProxy.deploy(DestructBeacon, seed);
        assertEq(DestructProxy, deployable);
    }

    function testCallCode() public {
        address DummyProxy = BeaconProxy.deploy(DummyBeacon, "");

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
        address RevertProxy = BeaconProxy.deploy(RevertBeacon, "");

        bytes memory initCode = abi.encodeWithSelector(bytes4(keccak256("initialize(string)")), "Hello World");
        cheats.expectRevert("Intentional REVERT");
        (bool success, ) = RevertProxy.call(initCode);
        assertTrue(success);
        assertEq(IDummy(RevertProxy).name(), "");
    }
}
