// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.7.6;

// Test Contracts

import {MockHome} from "./MockHome.sol";

// Bridge Contracts
import {BridgeRouterHarness} from "../harness/BridgeRouterHarness.sol";
import {TokenRegistryHarness} from "../harness/TokenRegistryHarness.sol";
import {TokenRegistry} from "../../TokenRegistry.sol";
import {BridgeToken} from "../../BridgeToken.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

// Upgrade Contracts
import {UpgradeBeacon} from "@nomad-xyz/contracts-core/contracts/upgrade/UpgradeBeacon.sol";
import {UpgradeBeaconController} from "@nomad-xyz/contracts-core/contracts/upgrade/UpgradeBeaconController.sol";

// Contract-core Contracts
import {XAppConnectionManager} from "@nomad-xyz/contracts-core/contracts/XAppConnectionManager.sol";
import {TypeCasts} from "@nomad-xyz/contracts-core/contracts/XAppConnectionManager.sol";

import "forge-std/Test.sol";
import "forge-std/console2.sol";

contract BridgeTest is Test {
    // Local variables
    uint256 mockUpdaterPK;
    address mockUpdater;
    address bridgeUser;
    uint32 localDomain;
    uint256 bridgeUserTokenAmount;

    // Remote variables
    bytes32 remoteBridgeRouter;
    uint32 remoteDomain;

    MockHome mockHome;
    BridgeRouterHarness bridgeRouter;
    XAppConnectionManager xAppConnectionManager;
    UpgradeBeaconController upgradeBeaconController;
    UpgradeBeacon tokenBeacon;

    // Token Registry for all tokens in the domain
    TokenRegistryHarness tokenRegistry;
    BridgeToken bridgeToken;

    // Implementation contract for all tokens in the domain
    ERC20Mock localToken;
    address remoteTokenLocalAddress;
    bytes32 remoteTokenRemoteAddress;

    function setUp() public virtual {
        // Mocks
        // The Private Key numbers are random and of no significance. They
        // serve as a seed for the cheatcode to generate a pseudorandom address.
        mockUpdaterPK = 420;
        mockUpdater = vm.addr(mockUpdaterPK);
        bridgeUser = vm.addr(9305);
        remoteBridgeRouter = TypeCasts.addressToBytes32(vm.addr(99123));
        bridgeUserTokenAmount = 10000;

        localToken = new ERC20Mock(
            "Fake",
            "FK",
            bridgeUser,
            bridgeUserTokenAmount
        );
        localDomain = 1500;
        remoteDomain = 3000;
        remoteTokenRemoteAddress = TypeCasts.addressToBytes32(address(0xBEEF));
        mockHome = new MockHome(localDomain);

        // Create implementations
        bridgeRouter = new BridgeRouterHarness();
        tokenRegistry = new TokenRegistryHarness();
        xAppConnectionManager = new XAppConnectionManager();
        upgradeBeaconController = new UpgradeBeaconController();
        bridgeToken = new BridgeToken();
        tokenBeacon = new UpgradeBeacon(
            address(bridgeToken),
            address(upgradeBeaconController)
        );
        initializeContracts();
        remoteTokenLocalAddress = createRemoteToken(
            remoteDomain,
            remoteTokenRemoteAddress
        );
    }

    function initializeContracts() public {
        tokenRegistry.initialize(
            address(tokenBeacon),
            address(xAppConnectionManager)
        );
        bridgeRouter.initialize(
            address(tokenRegistry),
            address(xAppConnectionManager)
        );
        // The Token Registry should be owned by the Bridge Router
        tokenRegistry.transferOwnership(address(bridgeRouter));
        xAppConnectionManager.setHome(address(mockHome));
        bridgeRouter.enrollRemoteRouter(remoteDomain, remoteBridgeRouter);
    }

    function createRemoteToken(uint32 remoteDomain, bytes32 remoteAddress)
        public
        returns (address)
    {
        address localAddress = tokenRegistry.exposed_deployToken(
            remoteDomain,
            remoteAddress
        );
        // The address is actually that of an UpgradeProxy that points
        // to the BridgeToken implementation
        BridgeToken remoteToken = BridgeToken(localAddress);
        assertEq(remoteToken.owner(), address(bridgeRouter));
        vm.startPrank(remoteToken.owner());
        remoteToken.mint(bridgeUser, bridgeUserTokenAmount);
        vm.stopPrank();
        return localAddress;
    }
}
