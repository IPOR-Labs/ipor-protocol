// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


import "../TestCommons.sol";
import "../../contracts/security/IporOwnable.sol";
import "../../contracts/libraries/errors/IporErrors.sol";
import "../utils/IporOracleSnapshot.sol";

contract UsdcSwitchIporProtocolImplementation is Test, TestCommons {
    // forge test --match-path test/fork/Usdc-switch-ipor-protocol-implementation.t.sol --fork-url https://eth-mainnet.g.alchemy.com/v2/YfDXHDZ3P5MKib-EPLiRuccxdhUxMTGE --fork-block-number 16406200

    uint256 private constant FORK_BLOCK_NUMBER = 16406200;
    address private _usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private _IporOracleOwner = 0xD92E9F039E4189c342b4067CC61f5d063960D248;
    address private _IporOracleUpdater = 0xC3A53976E9855d815A08f577C2BEef2a799470b7;
    address private _IporOracleProxy = 0x421C69EAa54646294Db30026aeE80D01988a6876;
    address private _IporOracleImplOld = 0x9C2A4eDaeD59A5b9de11c1C0eAfd8b7da751D64C;

    uint256 private _newIndex = 27658918161141365;
    // without any actions
    string private constant INIT_SNAPSHOT_FILE_NAME = "/iporOracleSnapshotStartUsdc.json";
    string private constant CLEAN_AFTER_UPDATE_IMPLEMENTATION_SNAPSHOT_FILE_NAME = "/iporOracleSnapshotAfterUpdateImplUsdc.json";

    string private constant SNAPSHOT_AFTER_UPDATE_INDEX_OLD_IMPL_FILE_NAME = "/iporOracleSnapshotOldImplAfterUpdateIndexUsdc.json";
    string private constant SNAPSHOT_AFTER_UPDATE_INDEX_New_IMPL_FILE_NAME = "/iporOracleSnapshotNiewImplAfterUpdateIndexUsdc.json";

    function setUp() public {
    }

    function testShouldUpgradeImplementation() public {
        //Get snapshot of iporOracle before switch implementation
        IporOracleSnapshot iporOracleSnapshotStart = new IporOracleSnapshot(_IporOracleProxy, _usdc);
        iporOracleSnapshotStart.snapshot();
        iporOracleSnapshotStart.toJson(INIT_SNAPSHOT_FILE_NAME);

        //Switch implementation of IporOracle
        IporOracle newIporOracle = new IporOracle();
        vm.prank(_IporOracleOwner);
        IporOracle(_IporOracleProxy).upgradeTo(address(newIporOracle));


        IporOracleSnapshot iporOracleSnapshotAfterUpgrade = new IporOracleSnapshot(_IporOracleProxy, _usdc);
        iporOracleSnapshotAfterUpgrade.snapshot();
        iporOracleSnapshotAfterUpgrade.toJson(CLEAN_AFTER_UPDATE_IMPLEMENTATION_SNAPSHOT_FILE_NAME);
        _assertTwoFile(INIT_SNAPSHOT_FILE_NAME, CLEAN_AFTER_UPDATE_IMPLEMENTATION_SNAPSHOT_FILE_NAME);

    }



    function testShouldUpdateIndexWhenUpgradeImplementation() public {
        // update index old implementation
        vm.prank(_IporOracleUpdater);
        IporOracle(_IporOracleProxy).updateIndex(_usdc, 27658918161141365);
        IporOracleSnapshot cleanAfterUpdateIndex = new IporOracleSnapshot(_IporOracleProxy, _usdc);
        cleanAfterUpdateIndex.snapshot();
        cleanAfterUpdateIndex.toJson(SNAPSHOT_AFTER_UPDATE_INDEX_OLD_IMPL_FILE_NAME);

        // update index new implementation
        vm.rollFork(FORK_BLOCK_NUMBER);
        IporOracle newIporOracle = new IporOracle();
        vm.prank(_IporOracleOwner);
        IporOracle(_IporOracleProxy).upgradeTo(address(newIporOracle));
        vm.prank(_IporOracleUpdater);
        IporOracle(_IporOracleProxy).updateIndex(_usdc,27658918161141365);
        IporOracleSnapshot newImplAfterUpdateIndex = new IporOracleSnapshot(_IporOracleProxy, _usdc);
        newImplAfterUpdateIndex.snapshot();
        newImplAfterUpdateIndex.toJson(SNAPSHOT_AFTER_UPDATE_INDEX_New_IMPL_FILE_NAME);

        //assert
        _assertTwoFile(SNAPSHOT_AFTER_UPDATE_INDEX_OLD_IMPL_FILE_NAME, SNAPSHOT_AFTER_UPDATE_INDEX_New_IMPL_FILE_NAME);
    }


    function testShouldUpdateIndexWhenUpgradeImplementation2() public {
        // update index old implementation
        vm.warp(block.timestamp + 60*60);
        vm.prank(_IporOracleUpdater);
        IporOracle(_IporOracleProxy).updateIndex(_usdc, 27658918161141365);
        IporOracleSnapshot cleanAfterUpdateIndex = new IporOracleSnapshot(_IporOracleProxy, _usdc);

        cleanAfterUpdateIndex.snapshot();
        cleanAfterUpdateIndex.toJson(SNAPSHOT_AFTER_UPDATE_INDEX_OLD_IMPL_FILE_NAME);

        // update index new implementation
        vm.rollFork(FORK_BLOCK_NUMBER);
        IporOracle newIporOracle = new IporOracle();
        vm.prank(_IporOracleOwner);
        IporOracle(_IporOracleProxy).upgradeTo(address(newIporOracle));
        vm.warp(block.timestamp + 60*60);
        vm.prank(_IporOracleUpdater);
        IporOracle(_IporOracleProxy).updateIndex(_usdc,27658918161141365);
        IporOracleSnapshot newImplAfterUpdateIndex = new IporOracleSnapshot(_IporOracleProxy, _usdc);
        newImplAfterUpdateIndex.snapshot();
        newImplAfterUpdateIndex.toJson(SNAPSHOT_AFTER_UPDATE_INDEX_New_IMPL_FILE_NAME);

        //assert
        _assertTwoFile(SNAPSHOT_AFTER_UPDATE_INDEX_OLD_IMPL_FILE_NAME, SNAPSHOT_AFTER_UPDATE_INDEX_New_IMPL_FILE_NAME);
    }

    function _assertTwoFile(string memory file1, string memory file2) internal {
        IporOracleSnapshot iporOracleSnapshot1 = new IporOracleSnapshot(_IporOracleProxy, _usdc);
        iporOracleSnapshot1.fromJson(file1);
        IporOracleSnapshot iporOracleSnapshot2 = new IporOracleSnapshot(_IporOracleProxy, _usdc);
        iporOracleSnapshot2.fromJson(file2);
        iporOracleSnapshot1.consoleLog();
        iporOracleSnapshot2.consoleLog();
        assertTrue(iporOracleSnapshot1.iporOracleVersion()!= iporOracleSnapshot2.iporOracleVersion());
        assertTrue(iporOracleSnapshot1.iporOracleVersion()!= 0);
        assertTrue(iporOracleSnapshot2.iporOracleVersion()!= 0);
        assertEq(iporOracleSnapshot1.iporOracleOwner(), iporOracleSnapshot2.iporOracleOwner());
        assertEq(iporOracleSnapshot1.iporOracleIsPaused(), iporOracleSnapshot2.iporOracleIsPaused());
        assertEq(iporOracleSnapshot1.blockNumber(), iporOracleSnapshot2.blockNumber());
        assertEq(iporOracleSnapshot1.timestamp(), iporOracleSnapshot2.timestamp());
        assertEq(iporOracleSnapshot1.indexValue(), iporOracleSnapshot2.indexValue());
        assertEq(iporOracleSnapshot1.ibtPrice(), iporOracleSnapshot2.ibtPrice());
        assertEq(iporOracleSnapshot1.exponentialMovingAverage(), iporOracleSnapshot2.exponentialMovingAverage());
        assertEq(iporOracleSnapshot1.exponentialWeightedMovingVariance(), iporOracleSnapshot2.exponentialWeightedMovingVariance());
        assertEq(iporOracleSnapshot1.lastUpdateTimestamp(), iporOracleSnapshot2.lastUpdateTimestamp());
        assertEq(iporOracleSnapshot1.accruedIndexValue(), iporOracleSnapshot2.accruedIndexValue());
        assertEq(iporOracleSnapshot1.accruedIbtPrice(), iporOracleSnapshot2.accruedIbtPrice());
        assertEq(iporOracleSnapshot1.accruedExponentialMovingAverage(), iporOracleSnapshot2.accruedExponentialMovingAverage());
        assertEq(iporOracleSnapshot1.accruedExponentialWeightedMovingVariance(), iporOracleSnapshot2.accruedExponentialWeightedMovingVariance());
    }

}
