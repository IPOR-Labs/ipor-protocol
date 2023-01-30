// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


import "../../TestCommons.sol";
import "./snapshots/MiltonSnapshot.sol";
import "../../../contracts/amm/Milton.sol";
import "../../../contracts/amm/MiltonDai.sol";
import "../../../contracts/amm/pool/Joseph.sol";
import "./snapshots/JosephSnapshot.sol";
import "../../../contracts/amm/pool/JosephDai.sol";
import "./snapshots/MiltonStorageSnapshot.sol";
import "./snapshots/StanleySnapshot.sol";
import "../ForkUtils.sol";
import "../../../contracts/amm/MiltonUsdc.sol";
import "../../../contracts/amm/pool/JosephUsdc.sol";
import "../../../contracts/amm/MiltonUsdt.sol";
import "../../../contracts/amm/pool/JosephUsdt.sol";

contract DaiMiltonJosephSwitchImplementation is Test, TestCommons, ForkUtils {

    address private _dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private _usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private _usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private _owner = 0xD92E9F039E4189c342b4067CC61f5d063960D248;

    address private _miltonProxyDai = 0xEd7d74AA7eB1f12F83dA36DFaC1de2257b4e7523;
    address private _josephProxyDai = 0x086d4daab14741b195deE65aFF050ba184B65045;
    address private _miltonStorageProxyDai = 0xb99f2a02c0851efdD417bd6935d2eFcd23c56e61;
    address private _stanleyProxyDai = 0xA6aC8B6AF789319A1Db994E25760Eb86F796e2B0;

    address private _miltonProxyUsdc = 0x137000352B4ed784e8fa8815d225c713AB2e7Dc9;
    address private _josephProxyUsdc = 0xC52569b5A349A7055E9192dBdd271F1Bd8133277;
    address private _miltonStorageProxyUsdc = 0xB3d1c1aB4D30800162da40eb18B3024154924ba5;
    address private _stanleyProxyUsdc = 0x7aa7b0B738C2570C2f9F892cB7cA5bB89b9BF260;

    address private _miltonProxyUsdt = 0x28BC58e600eF718B9E97d294098abecb8c96b687;
    address private _josephProxyUsdt = 0x33C5A44fd6E76Fc2b50a9187CfeaC336A74324AC;
    address private _miltonStorageProxyUsdt = 0x364f116352EB95033D73822bA81257B8c1f5B1CE;
    address private _stanleyProxyUsdt = 0x8e679C1d67Af0CD4b314896856f09ece9E64D6B5;


    function setUp() public {
    }

    function testShouldUpgradeDaiImplementation() public {
        //Get snapshot of milton before switch implementation
        MiltonSnapshot miltonSnapshotStart = new MiltonSnapshot(_miltonProxyDai);
        miltonSnapshotStart.snapshot();

        JosephSnapshot josephSnapshotStart = new JosephSnapshot(_josephProxyDai);
        josephSnapshotStart.snapshot();

        MiltonStorageSnapshot miltonStorageSnapshotStart = new MiltonStorageSnapshot(_miltonStorageProxyDai);
        miltonStorageSnapshotStart.snapshot();

        StanleySnapshot stanleySnapshotStart = new StanleySnapshot(_stanleyProxyDai);
        stanleySnapshotStart.snapshot();

        vm.makePersistent(address(miltonSnapshotStart));
        vm.makePersistent(address(josephSnapshotStart));
        vm.makePersistent(address(miltonStorageSnapshotStart));
        vm.makePersistent(address(stanleySnapshotStart));

        //Switch implementation of Milton
        Milton newMilton = new MiltonDai();
        vm.prank(_owner);
        Milton(_miltonProxyDai).upgradeTo(address(newMilton));

        //switch implementation of Joseph
        Joseph newJoseph = new JosephDai();
        vm.prank(_owner);
        Joseph(_josephProxyDai).upgradeTo(address(newJoseph));

        //Get snapshot after upgrade
        MiltonSnapshot miltonSnapshotAfterUpgrade = new MiltonSnapshot(_miltonProxyDai);
        miltonSnapshotAfterUpgrade.snapshot();

        JosephSnapshot josephSnapshotAfterUpgrade = new JosephSnapshot(_josephProxyDai);
        josephSnapshotAfterUpgrade.snapshot();

        MiltonStorageSnapshot miltonStorageSnapshotAfterUpgrade = new MiltonStorageSnapshot(_miltonStorageProxyDai);
        miltonStorageSnapshotAfterUpgrade.snapshot();

        StanleySnapshot stanleySnapshotAfterUpgrade = new StanleySnapshot(_stanleyProxyDai);
        stanleySnapshotAfterUpgrade.snapshot();

        vm.makePersistent(address(miltonSnapshotAfterUpgrade));
        vm.makePersistent(address(josephSnapshotAfterUpgrade));
        vm.makePersistent(address(miltonStorageSnapshotAfterUpgrade));
        vm.makePersistent(address(stanleySnapshotAfterUpgrade));

        //Assert files
        miltonSnapshotStart.assert( miltonSnapshotStart, miltonSnapshotAfterUpgrade);
        josephSnapshotStart.assert( josephSnapshotStart, josephSnapshotAfterUpgrade);
        miltonStorageSnapshotStart.assert( miltonStorageSnapshotStart, miltonStorageSnapshotAfterUpgrade);
        stanleySnapshotStart.assert( stanleySnapshotStart, stanleySnapshotAfterUpgrade);

    }

    function testShouldUpgradeDaiImplementationAndInteract() public {
        uint256 blockNumber = block.number;
       basicInteractWithAmm(_owner, _dai, _josephProxyDai, _miltonProxyDai);
        //Get snapshot of milton before switch implementation
        MiltonSnapshot miltonSnapshotStart = new MiltonSnapshot(_miltonProxyDai);
        miltonSnapshotStart.snapshot();

        JosephSnapshot josephSnapshotStart = new JosephSnapshot(_josephProxyDai);
        josephSnapshotStart.snapshot();

        MiltonStorageSnapshot miltonStorageSnapshotStart = new MiltonStorageSnapshot(_miltonStorageProxyDai);
        miltonStorageSnapshotStart.snapshot();

        StanleySnapshot stanleySnapshotStart = new StanleySnapshot(_stanleyProxyDai);
        stanleySnapshotStart.snapshot();

        vm.makePersistent(address(miltonSnapshotStart));
        vm.makePersistent(address(josephSnapshotStart));
        vm.makePersistent(address(miltonStorageSnapshotStart));
        vm.makePersistent(address(stanleySnapshotStart));

        //rollback
        vm.rollFork(blockNumber);


        //Switch implementation of Milton
        Milton newMilton = new MiltonDai();
        vm.prank(_owner);
        Milton(_miltonProxyDai).upgradeTo(address(newMilton));

        //switch implementation of Joseph
        Joseph newJoseph = new JosephDai();
        vm.prank(_owner);
        Joseph(_josephProxyDai).upgradeTo(address(newJoseph));
        vm.prank(_owner);
        Joseph(_josephProxyDai).addAppointedToRebalance(_owner);

       basicInteractWithAmm(_owner, _dai, _josephProxyDai, _miltonProxyDai);

        //Get snapshot after upgrade
        MiltonSnapshot miltonSnapshotAfterUpgrade = new MiltonSnapshot(_miltonProxyDai);
        miltonSnapshotAfterUpgrade.snapshot();

        JosephSnapshot josephSnapshotAfterUpgrade = new JosephSnapshot(_josephProxyDai);
        josephSnapshotAfterUpgrade.snapshot();

        MiltonStorageSnapshot miltonStorageSnapshotAfterUpgrade = new MiltonStorageSnapshot(_miltonStorageProxyDai);
        miltonStorageSnapshotAfterUpgrade.snapshot();

        StanleySnapshot stanleySnapshotAfterUpgrade = new StanleySnapshot(_stanleyProxyDai);
        stanleySnapshotAfterUpgrade.snapshot();

        vm.makePersistent(address(miltonSnapshotAfterUpgrade));
        vm.makePersistent(address(josephSnapshotAfterUpgrade));
        vm.makePersistent(address(miltonStorageSnapshotAfterUpgrade));
        vm.makePersistent(address(stanleySnapshotAfterUpgrade));

        //Assert files
        miltonSnapshotStart.assert( miltonSnapshotStart, miltonSnapshotAfterUpgrade);
        josephSnapshotStart.assert( josephSnapshotStart, josephSnapshotAfterUpgrade);
        miltonStorageSnapshotStart.assert( miltonStorageSnapshotStart, miltonStorageSnapshotAfterUpgrade);
        stanleySnapshotStart.assert( stanleySnapshotStart, stanleySnapshotAfterUpgrade);

    }

    function testShouldUpgradeUsdcImplementation() public {
        //Get snapshot of milton before switch implementation
        MiltonSnapshot miltonSnapshotStart = new MiltonSnapshot(_miltonProxyUsdc);
        miltonSnapshotStart.snapshot();

        JosephSnapshot josephSnapshotStart = new JosephSnapshot(_josephProxyUsdc);
        josephSnapshotStart.snapshot();

        MiltonStorageSnapshot miltonStorageSnapshotStart = new MiltonStorageSnapshot(_miltonStorageProxyUsdc);
        miltonStorageSnapshotStart.snapshot();

        StanleySnapshot stanleySnapshotStart = new StanleySnapshot(_stanleyProxyUsdc);
        stanleySnapshotStart.snapshot();

        vm.makePersistent(address(miltonSnapshotStart));
        vm.makePersistent(address(josephSnapshotStart));
        vm.makePersistent(address(miltonStorageSnapshotStart));
        vm.makePersistent(address(stanleySnapshotStart));

        //Switch implementation of Milton
        Milton newMilton = new MiltonUsdc();
        vm.prank(_owner);
        Milton(_miltonProxyUsdc).upgradeTo(address(newMilton));

        //switch implementation of Joseph
        Joseph newJoseph = new JosephUsdc();
        vm.prank(_owner);
        Joseph(_josephProxyUsdc).upgradeTo(address(newJoseph));

        //Get snapshot after upgrade
        MiltonSnapshot miltonSnapshotAfterUpgrade = new MiltonSnapshot(_miltonProxyUsdc);
        miltonSnapshotAfterUpgrade.snapshot();

        JosephSnapshot josephSnapshotAfterUpgrade = new JosephSnapshot(_josephProxyUsdc);
        josephSnapshotAfterUpgrade.snapshot();

        MiltonStorageSnapshot miltonStorageSnapshotAfterUpgrade = new MiltonStorageSnapshot(_miltonStorageProxyUsdc);
        miltonStorageSnapshotAfterUpgrade.snapshot();

        StanleySnapshot stanleySnapshotAfterUpgrade = new StanleySnapshot(_stanleyProxyUsdc);
        stanleySnapshotAfterUpgrade.snapshot();

        vm.makePersistent(address(miltonSnapshotAfterUpgrade));
        vm.makePersistent(address(josephSnapshotAfterUpgrade));
        vm.makePersistent(address(miltonStorageSnapshotAfterUpgrade));
        vm.makePersistent(address(stanleySnapshotAfterUpgrade));

        //Assert files
        miltonSnapshotStart.assert( miltonSnapshotStart, miltonSnapshotAfterUpgrade);
        josephSnapshotStart.assert( josephSnapshotStart, josephSnapshotAfterUpgrade);
        miltonStorageSnapshotStart.assert( miltonStorageSnapshotStart, miltonStorageSnapshotAfterUpgrade);
        stanleySnapshotStart.assert( stanleySnapshotStart, stanleySnapshotAfterUpgrade);

    }

    function testShouldUpgradeUsdcImplementationAndInteract() public {
        uint256 blockNumber = block.number;
        basicInteractWithAmm(_owner, _usdc, _josephProxyUsdc, _miltonProxyUsdc);
        //Get snapshot of milton before switch implementation
        MiltonSnapshot miltonSnapshotStart = new MiltonSnapshot(_miltonProxyUsdc);
        miltonSnapshotStart.snapshot();

        JosephSnapshot josephSnapshotStart = new JosephSnapshot(_josephProxyUsdc);
        josephSnapshotStart.snapshot();

        MiltonStorageSnapshot miltonStorageSnapshotStart = new MiltonStorageSnapshot(_miltonStorageProxyUsdc);
        miltonStorageSnapshotStart.snapshot();

        StanleySnapshot stanleySnapshotStart = new StanleySnapshot(_stanleyProxyUsdc);
        stanleySnapshotStart.snapshot();

        vm.makePersistent(address(miltonSnapshotStart));
        vm.makePersistent(address(josephSnapshotStart));
        vm.makePersistent(address(miltonStorageSnapshotStart));
        vm.makePersistent(address(stanleySnapshotStart));

        //rollback
        vm.rollFork(blockNumber);


        //Switch implementation of Milton
        Milton newMilton = new MiltonUsdc();
        vm.prank(_owner);
        Milton(_miltonProxyUsdc).upgradeTo(address(newMilton));

        //switch implementation of Joseph
        Joseph newJoseph = new JosephUsdc();
        vm.prank(_owner);
        Joseph(_josephProxyUsdc).upgradeTo(address(newJoseph));
        vm.prank(_owner);
        Joseph(_josephProxyUsdc).addAppointedToRebalance(_owner);

        basicInteractWithAmm(_owner, _usdc, _josephProxyUsdc, _miltonProxyUsdc);

        //Get snapshot after upgrade
        MiltonSnapshot miltonSnapshotAfterUpgrade = new MiltonSnapshot(_miltonProxyUsdc);
        miltonSnapshotAfterUpgrade.snapshot();

        JosephSnapshot josephSnapshotAfterUpgrade = new JosephSnapshot(_josephProxyUsdc);
        josephSnapshotAfterUpgrade.snapshot();

        MiltonStorageSnapshot miltonStorageSnapshotAfterUpgrade = new MiltonStorageSnapshot(_miltonStorageProxyUsdc);
        miltonStorageSnapshotAfterUpgrade.snapshot();

        StanleySnapshot stanleySnapshotAfterUpgrade = new StanleySnapshot(_stanleyProxyUsdc);
        stanleySnapshotAfterUpgrade.snapshot();

        vm.makePersistent(address(miltonSnapshotAfterUpgrade));
        vm.makePersistent(address(josephSnapshotAfterUpgrade));
        vm.makePersistent(address(miltonStorageSnapshotAfterUpgrade));
        vm.makePersistent(address(stanleySnapshotAfterUpgrade));

        //Assert files
        miltonSnapshotStart.assert( miltonSnapshotStart, miltonSnapshotAfterUpgrade);
        josephSnapshotStart.assert( josephSnapshotStart, josephSnapshotAfterUpgrade);
        miltonStorageSnapshotStart.assert( miltonStorageSnapshotStart, miltonStorageSnapshotAfterUpgrade);
        stanleySnapshotStart.assert( stanleySnapshotStart, stanleySnapshotAfterUpgrade);
    }

    function testShouldUpgradeUsdtImplementation() public {
        //Get snapshot of milton before switch implementation
        MiltonSnapshot miltonSnapshotStart = new MiltonSnapshot(_miltonProxyUsdt);
        miltonSnapshotStart.snapshot();

        JosephSnapshot josephSnapshotStart = new JosephSnapshot(_josephProxyUsdt);
        josephSnapshotStart.snapshot();

        MiltonStorageSnapshot miltonStorageSnapshotStart = new MiltonStorageSnapshot(_miltonStorageProxyUsdt);
        miltonStorageSnapshotStart.snapshot();

        StanleySnapshot stanleySnapshotStart = new StanleySnapshot(_stanleyProxyUsdt);
        stanleySnapshotStart.snapshot();

        vm.makePersistent(address(miltonSnapshotStart));
        vm.makePersistent(address(josephSnapshotStart));
        vm.makePersistent(address(miltonStorageSnapshotStart));
        vm.makePersistent(address(stanleySnapshotStart));

        //Switch implementation of Milton
        Milton newMilton = new MiltonUsdt();
        vm.prank(_owner);
        Milton(_miltonProxyUsdt).upgradeTo(address(newMilton));

        //switch implementation of Joseph
        Joseph newJoseph = new JosephUsdt();
        vm.prank(_owner);
        Joseph(_josephProxyUsdt).upgradeTo(address(newJoseph));

        //Get snapshot after upgrade
        MiltonSnapshot miltonSnapshotAfterUpgrade = new MiltonSnapshot(_miltonProxyUsdt);
        miltonSnapshotAfterUpgrade.snapshot();

        JosephSnapshot josephSnapshotAfterUpgrade = new JosephSnapshot(_josephProxyUsdt);
        josephSnapshotAfterUpgrade.snapshot();

        MiltonStorageSnapshot miltonStorageSnapshotAfterUpgrade = new MiltonStorageSnapshot(_miltonStorageProxyUsdt);
        miltonStorageSnapshotAfterUpgrade.snapshot();

        StanleySnapshot stanleySnapshotAfterUpgrade = new StanleySnapshot(_stanleyProxyUsdt);
        stanleySnapshotAfterUpgrade.snapshot();

        vm.makePersistent(address(miltonSnapshotAfterUpgrade));
        vm.makePersistent(address(josephSnapshotAfterUpgrade));
        vm.makePersistent(address(miltonStorageSnapshotAfterUpgrade));
        vm.makePersistent(address(stanleySnapshotAfterUpgrade));

        //Assert files
        miltonSnapshotStart.assert( miltonSnapshotStart, miltonSnapshotAfterUpgrade);
        josephSnapshotStart.assert( josephSnapshotStart, josephSnapshotAfterUpgrade);
        miltonStorageSnapshotStart.assert( miltonStorageSnapshotStart, miltonStorageSnapshotAfterUpgrade);
        stanleySnapshotStart.assert( stanleySnapshotStart, stanleySnapshotAfterUpgrade);

    }

    function testShouldUpgradeUsdtImplementationAndInteract() public {
        uint256 blockNumber = block.number;
        basicInteractWithAmm(_owner, _usdt, _josephProxyUsdt, _miltonProxyUsdt);
        //Get snapshot of milton before switch implementation
        MiltonSnapshot miltonSnapshotStart = new MiltonSnapshot(_miltonProxyUsdt);
        miltonSnapshotStart.snapshot();

        JosephSnapshot josephSnapshotStart = new JosephSnapshot(_josephProxyUsdt);
        josephSnapshotStart.snapshot();

        MiltonStorageSnapshot miltonStorageSnapshotStart = new MiltonStorageSnapshot(_miltonStorageProxyUsdt);
        miltonStorageSnapshotStart.snapshot();

        StanleySnapshot stanleySnapshotStart = new StanleySnapshot(_stanleyProxyUsdt);
        stanleySnapshotStart.snapshot();

        vm.makePersistent(address(miltonSnapshotStart));
        vm.makePersistent(address(josephSnapshotStart));
        vm.makePersistent(address(miltonStorageSnapshotStart));
        vm.makePersistent(address(stanleySnapshotStart));

        //rollback
        vm.rollFork(blockNumber);


        //Switch implementation of Milton
        Milton newMilton = new MiltonUsdt();
        vm.prank(_owner);
        Milton(_miltonProxyUsdt).upgradeTo(address(newMilton));

        //switch implementation of Joseph
        Joseph newJoseph = new JosephUsdt();
        vm.prank(_owner);
        Joseph(_josephProxyUsdt).upgradeTo(address(newJoseph));
        vm.prank(_owner);
        Joseph(_josephProxyUsdt).addAppointedToRebalance(_owner);

        basicInteractWithAmm(_owner, _usdt, _josephProxyUsdt, _miltonProxyUsdt);

        //Get snapshot after upgrade
        MiltonSnapshot miltonSnapshotAfterUpgrade = new MiltonSnapshot(_miltonProxyUsdt);
        miltonSnapshotAfterUpgrade.snapshot();

        JosephSnapshot josephSnapshotAfterUpgrade = new JosephSnapshot(_josephProxyUsdt);
        josephSnapshotAfterUpgrade.snapshot();

        MiltonStorageSnapshot miltonStorageSnapshotAfterUpgrade = new MiltonStorageSnapshot(_miltonStorageProxyUsdt);
        miltonStorageSnapshotAfterUpgrade.snapshot();

        StanleySnapshot stanleySnapshotAfterUpgrade = new StanleySnapshot(_stanleyProxyUsdt);
        stanleySnapshotAfterUpgrade.snapshot();

        vm.makePersistent(address(miltonSnapshotAfterUpgrade));
        vm.makePersistent(address(josephSnapshotAfterUpgrade));
        vm.makePersistent(address(miltonStorageSnapshotAfterUpgrade));
        vm.makePersistent(address(stanleySnapshotAfterUpgrade));

        //Assert files
        miltonSnapshotStart.assert( miltonSnapshotStart, miltonSnapshotAfterUpgrade);
        josephSnapshotStart.assert( josephSnapshotStart, josephSnapshotAfterUpgrade);
        miltonStorageSnapshotStart.assert( miltonStorageSnapshotStart, miltonStorageSnapshotAfterUpgrade);
        stanleySnapshotStart.assert( stanleySnapshotStart, stanleySnapshotAfterUpgrade);
    }

}