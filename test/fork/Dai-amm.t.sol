// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


import "../TestCommons.sol";
import "./MiltonSnapshot.sol";
import "../../contracts/amm/Milton.sol";
import "../../contracts/amm/MiltonDai.sol";
import "../../contracts/amm/pool/Joseph.sol";
import "./JosephSnapshot.sol";
import "../../contracts/amm/pool/JosephDai.sol";

contract DaiSwitchAmmImplementation is Test, TestCommons {
// forge test --match-path test/fork/Dai-amm.t.sol --fork-url https://eth-mainnet.g.alchemy.com/v2/YfDXHDZ3P5MKib-EPLiRuccxdhUxMTGE --fork-block-number 16406200

    uint256 private constant FORK_BLOCK_NUMBER = 16406200;
    address private _dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private _MiltonProxyDai = 0xEd7d74AA7eB1f12F83dA36DFaC1de2257b4e7523;
    address private _Owner = 0xD92E9F039E4189c342b4067CC61f5d063960D248;
    address private _JosephProxyDai = 0x086d4daab14741b195deE65aFF050ba184B65045;


    function setUp() public {
    }

    function testShouldUpgradeImplementation() public {

        //  interact with amm
        //Get snapshot of milton before switch implementation
        MiltonSnapshot miltonSnapshotStart = new MiltonSnapshot(_MiltonProxyDai);
        miltonSnapshotStart.snapshot();

        JosephSnapshot josephSnapshotStart = new JosephSnapshot(_JosephProxyDai);
        josephSnapshotStart.snapshot();


        //rollback



        //Switch implementation of Milton
        Milton newMilton = new MiltonDai();
        vm.prank(_Owner);
        Milton(_MiltonProxyDai).upgradeTo(address(newMilton));

        //switch implementation of Joseph
        Joseph newJoseph = new JosephDai();
        vm.prank(_Owner);
        Joseph(_JosephProxyDai).upgradeTo(address(newJoseph));


        //  interact with amm

        //Get snapshot after upgrade
        MiltonSnapshot miltonSnapshotAfterUpgrade = new MiltonSnapshot(_MiltonProxyDai);
        miltonSnapshotAfterUpgrade.snapshot();

        JosephSnapshot josephSnapshotAfterUpgrade = new JosephSnapshot(_JosephProxyDai);
        josephSnapshotAfterUpgrade.snapshot();

        //Assert files
        _assertMiltonSnapshot( miltonSnapshotStart, miltonSnapshotAfterUpgrade);
    _assertJosephSnapshot( josephSnapshotStart, josephSnapshotAfterUpgrade);
    }

    function _assertMiltonSnapshot(MiltonSnapshot  miltonSnapshot1, MiltonSnapshot  miltonSnapshot2) private {
                assertEq(miltonSnapshot1.miltonJoseph(), miltonSnapshot2.miltonJoseph());
                assertEq(miltonSnapshot1.miltonSpreadModel(), miltonSnapshot2.miltonSpreadModel());
                assertEq(miltonSnapshot1.miltonOwner(), miltonSnapshot2.miltonOwner());
                assertEq(miltonSnapshot1.miltonFacadeDataProviderOwner(), miltonSnapshot2.miltonFacadeDataProviderOwner());
                assertTrue(miltonSnapshot1.miltonVersion()!=miltonSnapshot2.miltonVersion());
                assertTrue(miltonSnapshot1.miltonVersion()!=0);
                assertTrue(0!=miltonSnapshot2.miltonVersion());
                assertEq(miltonSnapshot1.miltonMaxSwapCollateralAmount(), miltonSnapshot2.miltonMaxSwapCollateralAmount());
                assertEq(miltonSnapshot1.miltonMaxLpUtilizationRate(), miltonSnapshot2.miltonMaxLpUtilizationRate());
                assertEq(miltonSnapshot1.miltonMaxLpUtilizationPerLegRate(), miltonSnapshot2.miltonMaxLpUtilizationPerLegRate());
                assertEq(miltonSnapshot1.miltonIncomeFeeRate(), miltonSnapshot2.miltonIncomeFeeRate());
                assertEq(miltonSnapshot1.miltonOpeningFeeRate(), miltonSnapshot2.miltonOpeningFeeRate());
                assertEq(miltonSnapshot1.miltonOpeningFeeTreasuryPortionRate(), miltonSnapshot2.miltonOpeningFeeTreasuryPortionRate());
                assertEq(miltonSnapshot1.miltonIporPublicationFee(), miltonSnapshot2.miltonIporPublicationFee());
                assertEq(miltonSnapshot1.miltonLiquidationDepositAmount(), miltonSnapshot2.miltonLiquidationDepositAmount());
                assertEq(miltonSnapshot1.miltonWadLiquidationDepositAmount(), miltonSnapshot2.miltonWadLiquidationDepositAmount());
                assertEq(miltonSnapshot1.miltonMaxLeverage(), miltonSnapshot2.miltonMaxLeverage());
                assertEq(miltonSnapshot1.miltonMinLeverage(), miltonSnapshot2.miltonMinLeverage());
                assertEq(miltonSnapshot1.miltonSpreadPayFixed(), miltonSnapshot2.miltonSpreadPayFixed());
                assertEq(miltonSnapshot1.miltonSpreadReceiveFixed(), miltonSnapshot2.miltonSpreadReceiveFixed());
                assertEq(miltonSnapshot1.miltonSoapPayFixed(), miltonSnapshot2.miltonSoapPayFixed());
                assertEq(miltonSnapshot1.miltonSoapReceiveFixed(), miltonSnapshot2.miltonSoapReceiveFixed());
                assertEq(miltonSnapshot1.miltonSoap(), miltonSnapshot2.miltonSoap());
                assertEq(miltonSnapshot1.totalCollateralPayFixed(), miltonSnapshot2.totalCollateralPayFixed());
                assertEq(miltonSnapshot1.totalCollateralReceiveFixed(), miltonSnapshot2.totalCollateralReceiveFixed());
                assertEq(miltonSnapshot1.liquidityPool(), miltonSnapshot2.liquidityPool());
                assertEq(miltonSnapshot1.vault(), miltonSnapshot2.vault());
                assertEq(miltonSnapshot1.miltonIsPaused(), miltonSnapshot2.miltonIsPaused());
                assertEq(miltonSnapshot1.blockNumber(), miltonSnapshot2.blockNumber());
                assertEq(miltonSnapshot1.blockTimestamp(), miltonSnapshot2.blockTimestamp());
    }

    function _assertJosephSnapshot(JosephSnapshot josephSnapshot1, JosephSnapshot josephSnapshot2) private {
        assertEq(josephSnapshot1.josephAsset(), josephSnapshot2.josephAsset());
        assertEq(josephSnapshot1.josephTreasury(), josephSnapshot2.josephTreasury());
        assertEq(josephSnapshot1.josephCharlieTreasuryManager(), josephSnapshot2.josephCharlieTreasuryManager());
        assertEq(josephSnapshot1.josephCharlieTreasury(), josephSnapshot2.josephCharlieTreasury());
        assertEq(josephSnapshot1.josephTreasuryManager(), josephSnapshot2.josephTreasuryManager());
        assertEq(josephSnapshot1.josephOwner(), josephSnapshot2.josephOwner());
        assertTrue(josephSnapshot1.josephVersion()!= josephSnapshot2.josephVersion());
        assertEq(josephSnapshot1.josephRedeemFeeRate(), josephSnapshot2.josephRedeemFeeRate());
        assertEq(josephSnapshot1.josephRedeemLpMaxUtilizationRate(), josephSnapshot2.josephRedeemLpMaxUtilizationRate());
        assertEq(josephSnapshot1.josephMiltonStanleyBalanceRatio(), josephSnapshot2.josephMiltonStanleyBalanceRatio());
        assertEq(josephSnapshot1.josephMaxLiquidityPoolBalance(), josephSnapshot2.josephMaxLiquidityPoolBalance());
        assertEq(josephSnapshot1.josephMaxLpAccountContribution(), josephSnapshot2.josephMaxLpAccountContribution());
        assertEq(josephSnapshot1.josephExchangeRate(), josephSnapshot2.josephExchangeRate());
        assertEq(josephSnapshot1.josephVaultReservesRatio(), josephSnapshot2.josephVaultReservesRatio());
        assertEq(josephSnapshot1.josephIsPaused(), josephSnapshot2.josephIsPaused());
        assertEq(josephSnapshot1.blockNumber(), josephSnapshot2.blockNumber());
        assertEq(josephSnapshot1.blockTimestamp(), josephSnapshot2.blockTimestamp());
    }
}