// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "../../TestCommons.sol";
import "./snapshots/AmmTreasurySnapshot.sol";
import "contracts/amm/AmmTreasury.sol";
import "contracts/amm/AmmTreasuryDai.sol";
import "contracts/amm/pool/Joseph.sol";
import "./snapshots/JosephSnapshot.sol";
import "contracts/amm/pool/JosephDai.sol";
import "./snapshots/AmmStorageSnapshot.sol";
import "./snapshots/AssetManagementSnapshot.sol";
import "../ForkUtils.sol";
import "contracts/amm/AmmTreasuryUsdc.sol";
import "contracts/amm/pool/JosephUsdc.sol";
import "contracts/amm/AmmTreasuryUsdt.sol";
import "contracts/amm/pool/JosephUsdt.sol";
import "../../utils/IporRiskManagementOracleUtils.sol";
import "../../utils/TestConstants.sol";

contract DaiAmmTreasuryJosephSwitchImplementation is Test, TestCommons, ForkUtils, IporRiskManagementOracleUtils {
    address private _dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private _usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private _usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private _owner = 0xD92E9F039E4189c342b4067CC61f5d063960D248;

    address private _ammTreasuryProxyDai = 0xEd7d74AA7eB1f12F83dA36DFaC1de2257b4e7523;
    address private _josephProxyDai = 0x086d4daab14741b195deE65aFF050ba184B65045;
    address private _ammStorageProxyDai = 0xb99f2a02c0851efdD417bd6935d2eFcd23c56e61;
    address private _assetManagementProxyDai = 0xA6aC8B6AF789319A1Db994E25760Eb86F796e2B0;

    address private _ammTreasuryProxyUsdc = 0x137000352B4ed784e8fa8815d225c713AB2e7Dc9;
    address private _josephProxyUsdc = 0xC52569b5A349A7055E9192dBdd271F1Bd8133277;
    address private _ammStorageProxyUsdc = 0xB3d1c1aB4D30800162da40eb18B3024154924ba5;
    address private _assetManagementProxyUsdc = 0x7aa7b0B738C2570C2f9F892cB7cA5bB89b9BF260;

    address private _ammTreasuryProxyUsdt = 0x28BC58e600eF718B9E97d294098abecb8c96b687;
    address private _josephProxyUsdt = 0x33C5A44fd6E76Fc2b50a9187CfeaC336A74324AC;
    address private _ammStorageProxyUsdt = 0x364f116352EB95033D73822bA81257B8c1f5B1CE;
    address private _assetManagementProxyUsdt = 0x8e679C1d67Af0CD4b314896856f09ece9E64D6B5;

    function setUp() public {}

    function testShouldUpgradeDaiImplementation() public {
        //Get snapshot of ammTreasury before switch implementation
        AmmTreasurySnapshot ammTreasurySnapshotStart = new AmmTreasurySnapshot(_ammTreasuryProxyDai);
        ammTreasurySnapshotStart.snapshot();

        JosephSnapshot josephSnapshotStart = new JosephSnapshot(_josephProxyDai);
        josephSnapshotStart.snapshot();

        AmmStorageSnapshot ammStorageSnapshotStart = new AmmStorageSnapshot(_ammStorageProxyDai);
        ammStorageSnapshotStart.snapshot();

        AssetManagementSnapshot assetManagementSnapshotStart = new AssetManagementSnapshot(_assetManagementProxyDai);
        assetManagementSnapshotStart.snapshot();

        IIporRiskManagementOracle iporRiskManagementOracle = createRiskManagementOracle(_dai);

        vm.makePersistent(address(ammTreasurySnapshotStart));
        vm.makePersistent(address(josephSnapshotStart));
        vm.makePersistent(address(ammStorageSnapshotStart));
        vm.makePersistent(address(assetManagementSnapshotStart));

        //Switch implementation of AmmTreasury
        AmmTreasury newAmmTreasury = new AmmTreasuryDai(address(iporRiskManagementOracle));
        vm.prank(_owner);
        AmmTreasury(_ammTreasuryProxyDai).upgradeTo(address(newAmmTreasury));

        //switch implementation of Joseph
        Joseph newJoseph = new JosephDai();
        vm.prank(_owner);
        Joseph(_josephProxyDai).upgradeTo(address(newJoseph));

        //Get snapshot after upgrade
        AmmTreasurySnapshot ammTreasurySnapshotAfterUpgrade = new AmmTreasurySnapshot(_ammTreasuryProxyDai);
        ammTreasurySnapshotAfterUpgrade.snapshot();

        JosephSnapshot josephSnapshotAfterUpgrade = new JosephSnapshot(_josephProxyDai);
        josephSnapshotAfterUpgrade.snapshot();

        AmmStorageSnapshot ammStorageSnapshotAfterUpgrade = new AmmStorageSnapshot(_ammStorageProxyDai);
        ammStorageSnapshotAfterUpgrade.snapshot();

        AssetManagementSnapshot assetManagementSnapshotAfterUpgrade = new AssetManagementSnapshot(_assetManagementProxyDai);
        assetManagementSnapshotAfterUpgrade.snapshot();

        vm.makePersistent(address(ammTreasurySnapshotAfterUpgrade));
        vm.makePersistent(address(josephSnapshotAfterUpgrade));
        vm.makePersistent(address(ammStorageSnapshotAfterUpgrade));
        vm.makePersistent(address(assetManagementSnapshotAfterUpgrade));

        //Assert files
        ammTreasurySnapshotStart.assertAmmTreasury(ammTreasurySnapshotStart, ammTreasurySnapshotAfterUpgrade);
        josephSnapshotStart.assertJoseph(josephSnapshotStart, josephSnapshotAfterUpgrade);
        ammStorageSnapshotStart.assertAmmTreasury(ammStorageSnapshotStart, ammStorageSnapshotAfterUpgrade);
        assetManagementSnapshotStart.assertAssetManagement(assetManagementSnapshotStart, assetManagementSnapshotAfterUpgrade);
    }

    //TODO: fix test
    function skipTestShouldUpgradeDaiImplementationAndInteract() public {
        uint256 blockNumber = block.number;
        basicInteractWithAmm(_owner, _dai, _josephProxyDai, _ammTreasuryProxyDai);
        //Get snapshot of ammTreasury before switch implementation
        AmmTreasurySnapshot ammTreasurySnapshotStart = new AmmTreasurySnapshot(_ammTreasuryProxyDai);
        ammTreasurySnapshotStart.snapshot();

        JosephSnapshot josephSnapshotStart = new JosephSnapshot(_josephProxyDai);
        josephSnapshotStart.snapshot();

        AmmStorageSnapshot ammStorageSnapshotStart = new AmmStorageSnapshot(_ammStorageProxyDai);
        ammStorageSnapshotStart.snapshot();

        AssetManagementSnapshot assetManagementSnapshotStart = new AssetManagementSnapshot(_assetManagementProxyDai);
        assetManagementSnapshotStart.snapshot();

        vm.makePersistent(address(ammTreasurySnapshotStart));
        vm.makePersistent(address(josephSnapshotStart));
        vm.makePersistent(address(ammStorageSnapshotStart));
        vm.makePersistent(address(assetManagementSnapshotStart));

        //rollback
        vm.rollFork(blockNumber);

        //Switch implementation of AmmTreasury
        IIporRiskManagementOracle iporRiskManagementOracle = createRiskManagementOracle(_dai);
        AmmTreasury newAmmTreasury = new AmmTreasuryDai(address(iporRiskManagementOracle));
        vm.prank(_owner);
        AmmTreasury(_ammTreasuryProxyDai).upgradeTo(address(newAmmTreasury));

        AmmStorage newAmmStorage = new AmmStorage();
        vm.prank(_owner);
        AmmStorage(_ammStorageProxyDai).upgradeTo(address(newAmmStorage));

        //switch implementation of Joseph
        Joseph newJoseph = new JosephDai();
        vm.prank(_owner);
        Joseph(_josephProxyDai).upgradeTo(address(newJoseph));
        vm.prank(_owner);
        Joseph(_josephProxyDai).addAppointedToRebalance(_owner);

        basicInteractWithAmm(_owner, _dai, _josephProxyDai, _ammTreasuryProxyDai);

        //Get snapshot after upgrade
        AmmTreasurySnapshot ammTreasurySnapshotAfterUpgrade = new AmmTreasurySnapshot(_ammTreasuryProxyDai);
        ammTreasurySnapshotAfterUpgrade.snapshot();

        JosephSnapshot josephSnapshotAfterUpgrade = new JosephSnapshot(_josephProxyDai);
        josephSnapshotAfterUpgrade.snapshot();

        AmmStorageSnapshot ammStorageSnapshotAfterUpgrade = new AmmStorageSnapshot(_ammStorageProxyDai);
        ammStorageSnapshotAfterUpgrade.snapshot();

        AssetManagementSnapshot assetManagementSnapshotAfterUpgrade = new AssetManagementSnapshot(_assetManagementProxyDai);
        assetManagementSnapshotAfterUpgrade.snapshot();

        vm.makePersistent(address(ammTreasurySnapshotAfterUpgrade));
        vm.makePersistent(address(josephSnapshotAfterUpgrade));
        vm.makePersistent(address(ammStorageSnapshotAfterUpgrade));
        vm.makePersistent(address(assetManagementSnapshotAfterUpgrade));

        //Assert files
        ammTreasurySnapshotStart.assertAmmTreasury(ammTreasurySnapshotStart, ammTreasurySnapshotAfterUpgrade);
        josephSnapshotStart.assertJoseph(josephSnapshotStart, josephSnapshotAfterUpgrade);
        ammStorageSnapshotStart.assertAmmTreasury(ammStorageSnapshotStart, ammStorageSnapshotAfterUpgrade);
        assetManagementSnapshotStart.assertAssetManagement(assetManagementSnapshotStart, assetManagementSnapshotAfterUpgrade);
    }

    function testShouldUpgradeUsdcImplementation() public {
        //Get snapshot of ammTreasury before switch implementation
        AmmTreasurySnapshot ammTreasurySnapshotStart = new AmmTreasurySnapshot(_ammTreasuryProxyUsdc);
        ammTreasurySnapshotStart.snapshot();

        JosephSnapshot josephSnapshotStart = new JosephSnapshot(_josephProxyUsdc);
        josephSnapshotStart.snapshot();

        AmmStorageSnapshot ammStorageSnapshotStart = new AmmStorageSnapshot(_ammStorageProxyUsdc);
        ammStorageSnapshotStart.snapshot();

        AssetManagementSnapshot assetManagementSnapshotStart = new AssetManagementSnapshot(_assetManagementProxyUsdc);
        assetManagementSnapshotStart.snapshot();

        IIporRiskManagementOracle iporRiskManagementOracle = createRiskManagementOracle(_usdc);

        vm.makePersistent(address(ammTreasurySnapshotStart));
        vm.makePersistent(address(josephSnapshotStart));
        vm.makePersistent(address(ammStorageSnapshotStart));
        vm.makePersistent(address(assetManagementSnapshotStart));

        //Switch implementation of AmmTreasury
        AmmTreasury newAmmTreasury = new AmmTreasuryUsdc(address(iporRiskManagementOracle));
        vm.prank(_owner);
        AmmTreasury(_ammTreasuryProxyUsdc).upgradeTo(address(newAmmTreasury));

        AmmStorage newAmmStorage = new AmmStorage();
        vm.prank(_owner);
        AmmStorage(_ammStorageProxyUsdc).upgradeTo(address(newAmmStorage));

        //switch implementation of Joseph
        Joseph newJoseph = new JosephUsdc();
        vm.prank(_owner);
        Joseph(_josephProxyUsdc).upgradeTo(address(newJoseph));

        //Get snapshot after upgrade
        AmmTreasurySnapshot ammTreasurySnapshotAfterUpgrade = new AmmTreasurySnapshot(_ammTreasuryProxyUsdc);
        ammTreasurySnapshotAfterUpgrade.snapshot();

        JosephSnapshot josephSnapshotAfterUpgrade = new JosephSnapshot(_josephProxyUsdc);
        josephSnapshotAfterUpgrade.snapshot();

        AmmStorageSnapshot ammStorageSnapshotAfterUpgrade = new AmmStorageSnapshot(_ammStorageProxyUsdc);
        ammStorageSnapshotAfterUpgrade.snapshot();

        AssetManagementSnapshot assetManagementSnapshotAfterUpgrade = new AssetManagementSnapshot(_assetManagementProxyUsdc);
        assetManagementSnapshotAfterUpgrade.snapshot();

        vm.makePersistent(address(ammTreasurySnapshotAfterUpgrade));
        vm.makePersistent(address(josephSnapshotAfterUpgrade));
        vm.makePersistent(address(ammStorageSnapshotAfterUpgrade));
        vm.makePersistent(address(assetManagementSnapshotAfterUpgrade));

        //Assert files
        ammTreasurySnapshotStart.assertWithIgnore(ammTreasurySnapshotStart, ammTreasurySnapshotAfterUpgrade);
        josephSnapshotStart.assertJoseph(josephSnapshotStart, josephSnapshotAfterUpgrade);
        ammStorageSnapshotStart.assertAmmTreasury(ammStorageSnapshotStart, ammStorageSnapshotAfterUpgrade);
        assetManagementSnapshotStart.assertAssetManagement(assetManagementSnapshotStart, assetManagementSnapshotAfterUpgrade);
    }

    // TODO: temporary disabled
    function skipTestShouldUpgradeUsdcImplementationAndInteract() public {
        uint256 blockNumber = block.number;
        basicInteractWithAmm(_owner, _usdc, _josephProxyUsdc, _ammTreasuryProxyUsdc);
        //Get snapshot of ammTreasury before switch implementation
        AmmTreasurySnapshot ammTreasurySnapshotStart = new AmmTreasurySnapshot(_ammTreasuryProxyUsdc);
        ammTreasurySnapshotStart.snapshot();

        JosephSnapshot josephSnapshotStart = new JosephSnapshot(_josephProxyUsdc);
        josephSnapshotStart.snapshot();

        AmmStorageSnapshot ammStorageSnapshotStart = new AmmStorageSnapshot(_ammStorageProxyUsdc);
        ammStorageSnapshotStart.snapshot();

        AssetManagementSnapshot assetManagementSnapshotStart = new AssetManagementSnapshot(_assetManagementProxyUsdc);
        assetManagementSnapshotStart.snapshot();

        vm.makePersistent(address(ammTreasurySnapshotStart));
        vm.makePersistent(address(josephSnapshotStart));
        vm.makePersistent(address(ammStorageSnapshotStart));
        vm.makePersistent(address(assetManagementSnapshotStart));

        //rollback
        vm.rollFork(blockNumber);

        //Switch implementation of AmmTreasury
        IIporRiskManagementOracle iporRiskManagementOracle = createRiskManagementOracle(_usdc);
        AmmTreasury newAmmTreasury = new AmmTreasuryUsdc(address(iporRiskManagementOracle));
        vm.prank(_owner);
        AmmTreasury(_ammTreasuryProxyUsdc).upgradeTo(address(newAmmTreasury));

        AmmStorage newAmmStorage = new AmmStorage();
        vm.prank(_owner);
        AmmStorage(_ammStorageProxyUsdc).upgradeTo(address(newAmmStorage));

        //switch implementation of Joseph
        Joseph newJoseph = new JosephUsdc();
        vm.prank(_owner);
        Joseph(_josephProxyUsdc).upgradeTo(address(newJoseph));

        vm.prank(_owner);
        Joseph(_josephProxyUsdc).addAppointedToRebalance(_owner);

        basicInteractWithAmm(_owner, _usdc, _josephProxyUsdc, _ammTreasuryProxyUsdc);

        //Get snapshot after upgrade
        AmmTreasurySnapshot ammTreasurySnapshotAfterUpgrade = new AmmTreasurySnapshot(_ammTreasuryProxyUsdc);
        ammTreasurySnapshotAfterUpgrade.snapshot();

        JosephSnapshot josephSnapshotAfterUpgrade = new JosephSnapshot(_josephProxyUsdc);
        josephSnapshotAfterUpgrade.snapshot();

        AmmStorageSnapshot ammStorageSnapshotAfterUpgrade = new AmmStorageSnapshot(_ammStorageProxyUsdc);
        ammStorageSnapshotAfterUpgrade.snapshot();

        AssetManagementSnapshot assetManagementSnapshotAfterUpgrade = new AssetManagementSnapshot(_assetManagementProxyUsdc);
        assetManagementSnapshotAfterUpgrade.snapshot();

        vm.makePersistent(address(ammTreasurySnapshotAfterUpgrade));
        vm.makePersistent(address(josephSnapshotAfterUpgrade));
        vm.makePersistent(address(ammStorageSnapshotAfterUpgrade));
        vm.makePersistent(address(assetManagementSnapshotAfterUpgrade));

        //Assert files
        ammTreasurySnapshotStart.assertAmmTreasury(ammTreasurySnapshotStart, ammTreasurySnapshotAfterUpgrade);
        josephSnapshotStart.assertJoseph(josephSnapshotStart, josephSnapshotAfterUpgrade);
        ammStorageSnapshotStart.assertAmmTreasury(ammStorageSnapshotStart, ammStorageSnapshotAfterUpgrade);
        assetManagementSnapshotStart.assertAssetManagement(assetManagementSnapshotStart, assetManagementSnapshotAfterUpgrade);
    }

    function testShouldUpgradeUsdtImplementation() public {
        //Get snapshot of ammTreasury before switch implementation
        AmmTreasurySnapshot ammTreasurySnapshotStart = new AmmTreasurySnapshot(_ammTreasuryProxyUsdt);
        ammTreasurySnapshotStart.snapshot();

        JosephSnapshot josephSnapshotStart = new JosephSnapshot(_josephProxyUsdt);
        josephSnapshotStart.snapshot();

        AmmStorageSnapshot ammStorageSnapshotStart = new AmmStorageSnapshot(_ammStorageProxyUsdt);
        ammStorageSnapshotStart.snapshot();

        AssetManagementSnapshot assetManagementSnapshotStart = new AssetManagementSnapshot(_assetManagementProxyUsdt);
        assetManagementSnapshotStart.snapshot();

        IIporRiskManagementOracle iporRiskManagementOracle = createRiskManagementOracle(_usdt);

        vm.makePersistent(address(ammTreasurySnapshotStart));
        vm.makePersistent(address(josephSnapshotStart));
        vm.makePersistent(address(ammStorageSnapshotStart));
        vm.makePersistent(address(assetManagementSnapshotStart));

        //Switch implementation of AmmTreasury
        AmmTreasury newAmmTreasury = new AmmTreasuryUsdt(address(iporRiskManagementOracle));
        vm.prank(_owner);
        AmmTreasury(_ammTreasuryProxyUsdt).upgradeTo(address(newAmmTreasury));

        //switch implementation of Joseph
        Joseph newJoseph = new JosephUsdt();
        vm.prank(_owner);
        Joseph(_josephProxyUsdt).upgradeTo(address(newJoseph));

        //Get snapshot after upgrade
        AmmTreasurySnapshot ammTreasurySnapshotAfterUpgrade = new AmmTreasurySnapshot(_ammTreasuryProxyUsdt);
        ammTreasurySnapshotAfterUpgrade.snapshot();

        JosephSnapshot josephSnapshotAfterUpgrade = new JosephSnapshot(_josephProxyUsdt);
        josephSnapshotAfterUpgrade.snapshot();

        AmmStorageSnapshot ammStorageSnapshotAfterUpgrade = new AmmStorageSnapshot(_ammStorageProxyUsdt);
        ammStorageSnapshotAfterUpgrade.snapshot();

        AssetManagementSnapshot assetManagementSnapshotAfterUpgrade = new AssetManagementSnapshot(_assetManagementProxyUsdt);
        assetManagementSnapshotAfterUpgrade.snapshot();

        vm.makePersistent(address(ammTreasurySnapshotAfterUpgrade));
        vm.makePersistent(address(josephSnapshotAfterUpgrade));
        vm.makePersistent(address(ammStorageSnapshotAfterUpgrade));
        vm.makePersistent(address(assetManagementSnapshotAfterUpgrade));

        //Assert files
        ammTreasurySnapshotStart.assertAmmTreasury(ammTreasurySnapshotStart, ammTreasurySnapshotAfterUpgrade);
        josephSnapshotStart.assertJoseph(josephSnapshotStart, josephSnapshotAfterUpgrade);
        ammStorageSnapshotStart.assertAmmTreasury(ammStorageSnapshotStart, ammStorageSnapshotAfterUpgrade);
        assetManagementSnapshotStart.assertAssetManagement(assetManagementSnapshotStart, assetManagementSnapshotAfterUpgrade);
    }

    //TODO: temporary skipped
    function skipTestShouldUpgradeUsdtImplementationAndInteract() public {
        uint256 blockNumber = block.number;
        basicInteractWithAmm(_owner, _usdt, _josephProxyUsdt, _ammTreasuryProxyUsdt);
        //Get snapshot of ammTreasury before switch implementation
        AmmTreasurySnapshot ammTreasurySnapshotStart = new AmmTreasurySnapshot(_ammTreasuryProxyUsdt);
        ammTreasurySnapshotStart.snapshot();

        JosephSnapshot josephSnapshotStart = new JosephSnapshot(_josephProxyUsdt);
        josephSnapshotStart.snapshot();

        AmmStorageSnapshot ammStorageSnapshotStart = new AmmStorageSnapshot(_ammStorageProxyUsdt);
        ammStorageSnapshotStart.snapshot();

        AssetManagementSnapshot assetManagementSnapshotStart = new AssetManagementSnapshot(_assetManagementProxyUsdt);
        assetManagementSnapshotStart.snapshot();

        vm.makePersistent(address(ammTreasurySnapshotStart));
        vm.makePersistent(address(josephSnapshotStart));
        vm.makePersistent(address(ammStorageSnapshotStart));
        vm.makePersistent(address(assetManagementSnapshotStart));

        //rollback
        vm.rollFork(blockNumber);

        //Switch implementation of AmmTreasury
        IIporRiskManagementOracle iporRiskManagementOracle = createRiskManagementOracle(_usdt);
        AmmTreasury newAmmTreasury = new AmmTreasuryUsdt(address(iporRiskManagementOracle));
        vm.prank(_owner);
        AmmTreasury(_ammTreasuryProxyUsdt).upgradeTo(address(newAmmTreasury));

        AmmStorage newAmmStorage = new AmmStorage();
        vm.prank(_owner);
        AmmStorage(_ammStorageProxyUsdt).upgradeTo(address(newAmmStorage));

        //switch implementation of Joseph
        Joseph newJoseph = new JosephUsdt();
        vm.prank(_owner);
        Joseph(_josephProxyUsdt).upgradeTo(address(newJoseph));

        vm.prank(_owner);
        Joseph(_josephProxyUsdt).addAppointedToRebalance(_owner);

        basicInteractWithAmm(_owner, _usdt, _josephProxyUsdt, _ammTreasuryProxyUsdt);

        //Get snapshot after upgrade
        AmmTreasurySnapshot ammTreasurySnapshotAfterUpgrade = new AmmTreasurySnapshot(_ammTreasuryProxyUsdt);
        ammTreasurySnapshotAfterUpgrade.snapshot();

        JosephSnapshot josephSnapshotAfterUpgrade = new JosephSnapshot(_josephProxyUsdt);
        josephSnapshotAfterUpgrade.snapshot();

        AmmStorageSnapshot ammStorageSnapshotAfterUpgrade = new AmmStorageSnapshot(_ammStorageProxyUsdt);
        ammStorageSnapshotAfterUpgrade.snapshot();

        AssetManagementSnapshot assetManagementSnapshotAfterUpgrade = new AssetManagementSnapshot(_assetManagementProxyUsdt);
        assetManagementSnapshotAfterUpgrade.snapshot();

        vm.makePersistent(address(ammTreasurySnapshotAfterUpgrade));
        vm.makePersistent(address(josephSnapshotAfterUpgrade));
        vm.makePersistent(address(ammStorageSnapshotAfterUpgrade));
        vm.makePersistent(address(assetManagementSnapshotAfterUpgrade));

        //Assert files
        ammTreasurySnapshotStart.assertAmmTreasury(ammTreasurySnapshotStart, ammTreasurySnapshotAfterUpgrade);
        josephSnapshotStart.assertJoseph(josephSnapshotStart, josephSnapshotAfterUpgrade);
        ammStorageSnapshotStart.assertAmmTreasury(ammStorageSnapshotStart, ammStorageSnapshotAfterUpgrade);
        assetManagementSnapshotStart.assertAssetManagement(assetManagementSnapshotStart, assetManagementSnapshotAfterUpgrade);
    }

    function createRiskManagementOracle(address assetAddress) internal returns (IIporRiskManagementOracle) {
        return
            getRiskManagementOracleAsset(
                _owner,
                assetAddress,
                TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                TestConstants.RMO_COLLATERAL_RATIO_80_PER,
                TestConstants.RMO_NOTIONAL_1B,
                TestConstants.RMO_SPREAD_0_1_PER
            );
    }
}
