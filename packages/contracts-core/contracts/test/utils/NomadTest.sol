// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.7.6;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../../UpdaterManager.sol";
import "./BadXapps.sol";
import "./GoodXapps.sol";
import {MerkleTest} from "./MerkleTest.sol";

contract NomadTest is Test {
    uint256 updaterPK = 1;
    uint256 fakeUpdaterPK = 2;
    address updater = vm.addr(updaterPK);
    address fakeUpdater = vm.addr(fakeUpdaterPK);
    address signer = vm.addr(3);
    address fakeSigner = vm.addr(4);

    uint32 homeDomain = 1500;
    uint32 remoteDomain = 1000;

    MerkleTest merkleTest;

    function setUp() public virtual {
        vm.label(updater, "updater");
        vm.label(fakeUpdater, "fake updater");
        vm.label(signer, "signer");
        vm.label(fakeSigner, "fake signer");

        merkleTest = new MerkleTest();
    }

    function getMessage(
        bytes32 oldRoot,
        bytes32 newRoot,
        uint32 domain
    ) public pure returns (bytes memory) {
        bytes memory message = abi.encodePacked(
            keccak256(abi.encodePacked(domain, "NOMAD")),
            oldRoot,
            newRoot
        );
        return message;
    }

    function signHomeUpdate(
        uint256 privKey,
        bytes32 oldRoot,
        bytes32 newRoot
    ) public returns (bytes memory) {
        bytes32 digest = keccak256(getMessage(oldRoot, newRoot, homeDomain));
        digest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", digest)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        return signature;
    }

    function signRemoteUpdate(
        uint256 privKey,
        bytes32 oldRoot,
        bytes32 newRoot
    ) public returns (bytes memory) {
        bytes32 digest = keccak256(getMessage(oldRoot, newRoot, remoteDomain));
        digest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", digest)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        return signature;
    }

    function stringToBytes32(string memory source)
        public
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }
}

contract NomadTestWithUpdaterManager is NomadTest {
    UpdaterManager updaterManager;

    function setUp() public virtual override {
        super.setUp();
        updaterManager = new UpdaterManager(updater);
    }
}

contract ReplicaHandlers is NomadTest {
    // Bad Handlers

    BadXappAssemblyRevert badXappAssemblyRevert;
    BadXappAssemblyReturnZero badXappAssemblyReturnZero;
    BadXappRevertData badXappRevertData;
    BadXappRevertRequireString badXappRevertRequireString;
    BadXappRevertRequire badXappRevertRequire;

    // Good Handlers

    GoodXappSimple goodXappSimple;

    function setUp() public virtual override {
        super.setUp();
        setUpBadHandlers();
    }

    function setUpBadHandlers() public {
        badXappAssemblyRevert = new BadXappAssemblyRevert();
        badXappAssemblyReturnZero = new BadXappAssemblyReturnZero();
        badXappRevertData = new BadXappRevertData();
        badXappRevertRequireString = new BadXappRevertRequireString();
        badXappRevertRequire = new BadXappRevertRequire();

        goodXappSimple = new GoodXappSimple();
    }
}
