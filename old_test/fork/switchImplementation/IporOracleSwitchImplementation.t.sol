// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "../../TestCommons.sol";
import "contracts/security/IporOwnable.sol";
import "contracts/libraries/errors/IporErrors.sol";
import "./snapshots/IporOracleSnapshot.sol";

contract SwitchIporOracleImplementation is Test, TestCommons {
    address private _dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private _usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private _usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    address private _IporOracleOwner = 0xD92E9F039E4189c342b4067CC61f5d063960D248;
    address private _IporOracleUpdater = 0xC3A53976E9855d815A08f577C2BEef2a799470b7;
    address private _IporOracleProxy = 0x421C69EAa54646294Db30026aeE80D01988a6876;

    uint256 private _newIndex = 27658918161141365;

    // without any actions

    function setUp() public {}

    // TODO: IL-2888 Turn on tests after the first index publication
    function skipTestShouldUpgradeImplementationCheckDai() public {
        //Get snapshot of iporOracle before switch implementation
        IporOracleSnapshot iporOracleSnapshotStart = new IporOracleSnapshot(_IporOracleProxy, _dai);
        iporOracleSnapshotStart.snapshot();
        vm.makePersistent(address(iporOracleSnapshotStart));

        //Switch implementation of IporOracle
        IporOracle newIporOracle = new IporOracle();
        vm.prank(_IporOracleOwner);
        IporOracle(_IporOracleProxy).upgradeTo(address(newIporOracle));

        IporOracleSnapshot iporOracleSnapshotAfterUpgrade = new IporOracleSnapshot(_IporOracleProxy, _dai);
        iporOracleSnapshotAfterUpgrade.snapshot();
        vm.makePersistent(address(iporOracleSnapshotAfterUpgrade));

        iporOracleSnapshotStart.assertIporOracle(iporOracleSnapshotStart, iporOracleSnapshotAfterUpgrade);
    }

    // TODO: IL-2888 Turn on tests after the first index publication
    function skipTestShouldUpgradeImplementationCheckUsdc() public {
        //Get snapshot of iporOracle before switch implementation
        IporOracleSnapshot iporOracleSnapshotStart = new IporOracleSnapshot(_IporOracleProxy, _usdc);
        iporOracleSnapshotStart.snapshot();

        //Switch implementation of IporOracle
        IporOracle newIporOracle = new IporOracle();
        vm.prank(_IporOracleOwner);
        IporOracle(_IporOracleProxy).upgradeTo(address(newIporOracle));

        IporOracleSnapshot iporOracleSnapshotAfterUpgrade = new IporOracleSnapshot(_IporOracleProxy, _usdc);
        iporOracleSnapshotAfterUpgrade.snapshot();

        iporOracleSnapshotStart.assertIporOracle(iporOracleSnapshotStart, iporOracleSnapshotAfterUpgrade);
    }

    // TODO: IL-2888 Turn on tests after the first index publication
    function skipTestShouldUpgradeImplementationCheckUsdt() public {
        //Get snapshot of iporOracle before switch implementation
        IporOracleSnapshot iporOracleSnapshotStart = new IporOracleSnapshot(_IporOracleProxy, _usdt);
        iporOracleSnapshotStart.snapshot();

        //Switch implementation of IporOracle
        IporOracle newIporOracle = new IporOracle();
        vm.prank(_IporOracleOwner);
        IporOracle(_IporOracleProxy).upgradeTo(address(newIporOracle));

        IporOracleSnapshot iporOracleSnapshotAfterUpgrade = new IporOracleSnapshot(_IporOracleProxy, _usdt);
        iporOracleSnapshotAfterUpgrade.snapshot();
        iporOracleSnapshotStart.assertIporOracle(iporOracleSnapshotStart, iporOracleSnapshotAfterUpgrade);
    }

    // TODO: IL-2888 Turn on tests after the first index publication
    function skipTestShouldUpdateIndexForDaiWhenUpgradeImplementation() public {
        // update index old implementation
        uint256 blockNumber = block.number;
        vm.prank(_IporOracleUpdater);
        IporOracle(_IporOracleProxy).updateIndex(_dai, 27658918161141365);
        IporOracleSnapshot cleanAfterUpdateIndex = new IporOracleSnapshot(_IporOracleProxy, _dai);
        cleanAfterUpdateIndex.snapshot();
        vm.makePersistent(address(cleanAfterUpdateIndex));

        // update index new implementation
        vm.rollFork(blockNumber);
        IporOracle newIporOracle = new IporOracle();
        vm.prank(_IporOracleOwner);
        IporOracle(_IporOracleProxy).upgradeTo(address(newIporOracle));
        vm.prank(_IporOracleUpdater);
        IporOracle(_IporOracleProxy).updateIndex(_dai, 27658918161141365);
        IporOracleSnapshot newImplAfterUpdateIndex = new IporOracleSnapshot(_IporOracleProxy, _dai);
        newImplAfterUpdateIndex.snapshot();
        vm.makePersistent(address(newImplAfterUpdateIndex));

        //assert
        cleanAfterUpdateIndex.assertIporOracle(cleanAfterUpdateIndex, newImplAfterUpdateIndex);
    }

    // TODO: IL-2888 Turn on tests after the first index publication
    function skipTestShouldUpdateIndexForUsdcWhenUpgradeImplementation() public {
        // update index old implementation
        uint256 blockNumber = block.number;
        vm.prank(_IporOracleUpdater);
        IporOracle(_IporOracleProxy).updateIndex(_usdc, 27658918161141365);
        IporOracleSnapshot cleanAfterUpdateIndex = new IporOracleSnapshot(_IporOracleProxy, _usdc);
        cleanAfterUpdateIndex.snapshot();
        vm.makePersistent(address(cleanAfterUpdateIndex));

        // update index new implementation
        vm.rollFork(blockNumber);
        IporOracle newIporOracle = new IporOracle();
        vm.prank(_IporOracleOwner);
        IporOracle(_IporOracleProxy).upgradeTo(address(newIporOracle));
        vm.prank(_IporOracleUpdater);
        IporOracle(_IporOracleProxy).updateIndex(_usdc, 27658918161141365);
        IporOracleSnapshot newImplAfterUpdateIndex = new IporOracleSnapshot(_IporOracleProxy, _usdc);
        newImplAfterUpdateIndex.snapshot();
        vm.makePersistent(address(newImplAfterUpdateIndex));

        //assert
        cleanAfterUpdateIndex.assertIporOracle(cleanAfterUpdateIndex, newImplAfterUpdateIndex);
    }

    // TODO: IL-2888 Turn on tests after the first index publication
    function skipTestShouldUpdateIndexForUsdtWhenUpgradeImplementation() public {
        // update index old implementation
        uint256 blockNumber = block.number;
        vm.prank(_IporOracleUpdater);
        IporOracle(_IporOracleProxy).updateIndex(_usdt, 27658918161141365);
        IporOracleSnapshot cleanAfterUpdateIndex = new IporOracleSnapshot(_IporOracleProxy, _usdt);
        cleanAfterUpdateIndex.snapshot();
        vm.makePersistent(address(cleanAfterUpdateIndex));

        // update index new implementation
        vm.rollFork(blockNumber);
        IporOracle newIporOracle = new IporOracle();
        vm.prank(_IporOracleOwner);
        IporOracle(_IporOracleProxy).upgradeTo(address(newIporOracle));
        vm.prank(_IporOracleUpdater);
        IporOracle(_IporOracleProxy).updateIndex(_usdt, 27658918161141365);
        IporOracleSnapshot newImplAfterUpdateIndex = new IporOracleSnapshot(_IporOracleProxy, _usdt);
        newImplAfterUpdateIndex.snapshot();
        vm.makePersistent(address(newImplAfterUpdateIndex));

        //assert
        cleanAfterUpdateIndex.assertIporOracle(cleanAfterUpdateIndex, newImplAfterUpdateIndex);
    }

    // TODO: IL-2888 Turn on tests after the first index publication
    function skipTestShouldUpdateIndexForDaiWhenUpgradeImplementation2() public {
        // update index old implementation
        uint256 blockNumber = block.number;
        vm.warp(block.timestamp + 60 * 60);
        vm.prank(_IporOracleUpdater);
        IporOracle(_IporOracleProxy).updateIndex(_dai, 27658918161141365);
        IporOracleSnapshot cleanAfterUpdateIndex = new IporOracleSnapshot(_IporOracleProxy, _dai);
        cleanAfterUpdateIndex.snapshot();
        vm.makePersistent(address(cleanAfterUpdateIndex));

        // update index new implementation
        vm.rollFork(blockNumber);
        IporOracle newIporOracle = new IporOracle();
        vm.prank(_IporOracleOwner);
        IporOracle(_IporOracleProxy).upgradeTo(address(newIporOracle));
        vm.warp(block.timestamp + 60 * 60);
        vm.prank(_IporOracleUpdater);
        IporOracle(_IporOracleProxy).updateIndex(_dai, 27658918161141365);
        IporOracleSnapshot newImplAfterUpdateIndex = new IporOracleSnapshot(_IporOracleProxy, _dai);
        newImplAfterUpdateIndex.snapshot();
        vm.makePersistent(address(newImplAfterUpdateIndex));

        //assert
        cleanAfterUpdateIndex.assertIporOracle(cleanAfterUpdateIndex, newImplAfterUpdateIndex);
    }

    // TODO: IL-2888 Turn on tests after the first index publication
    function skipTestShouldUpdateIndexForUsdcWhenUpgradeImplementation2() public {
        // update index old implementation
        uint256 blockNumber = block.number;
        vm.warp(block.timestamp + 60 * 60);
        vm.prank(_IporOracleUpdater);
        IporOracle(_IporOracleProxy).updateIndex(_usdc, 27658918161141365);
        IporOracleSnapshot cleanAfterUpdateIndex = new IporOracleSnapshot(_IporOracleProxy, _usdc);

        cleanAfterUpdateIndex.snapshot();
        vm.makePersistent(address(cleanAfterUpdateIndex));

        // update index new implementation
        vm.rollFork(blockNumber);
        IporOracle newIporOracle = new IporOracle();
        vm.prank(_IporOracleOwner);
        IporOracle(_IporOracleProxy).upgradeTo(address(newIporOracle));
        vm.warp(block.timestamp + 60 * 60);
        vm.prank(_IporOracleUpdater);
        IporOracle(_IporOracleProxy).updateIndex(_usdc, 27658918161141365);
        IporOracleSnapshot newImplAfterUpdateIndex = new IporOracleSnapshot(_IporOracleProxy, _usdc);
        newImplAfterUpdateIndex.snapshot();

        //assert
        cleanAfterUpdateIndex.assertIporOracle(cleanAfterUpdateIndex, newImplAfterUpdateIndex);
    }

    // TODO: IL-2888 Turn on tests after the first index publication
    function skipTestShouldUpdateIndexForUsdtWhenUpgradeImplementation2() public {
        // update index old implementation
        uint256 blockNumber = block.number;
        vm.warp(block.timestamp + 60 * 60);
        vm.prank(_IporOracleUpdater);
        IporOracle(_IporOracleProxy).updateIndex(_usdt, 27658918161141365);
        IporOracleSnapshot cleanAfterUpdateIndex = new IporOracleSnapshot(_IporOracleProxy, _usdt);
        cleanAfterUpdateIndex.snapshot();
        vm.makePersistent(address(cleanAfterUpdateIndex));

        // update index new implementation
        vm.rollFork(blockNumber);
        IporOracle newIporOracle = new IporOracle();
        vm.prank(_IporOracleOwner);
        IporOracle(_IporOracleProxy).upgradeTo(address(newIporOracle));
        vm.warp(block.timestamp + 60 * 60);
        vm.prank(_IporOracleUpdater);
        IporOracle(_IporOracleProxy).updateIndex(_usdt, 27658918161141365);
        IporOracleSnapshot newImplAfterUpdateIndex = new IporOracleSnapshot(_IporOracleProxy, _usdt);
        newImplAfterUpdateIndex.snapshot();

        //assert
        cleanAfterUpdateIndex.assertIporOracle(cleanAfterUpdateIndex, newImplAfterUpdateIndex);
    }
}
