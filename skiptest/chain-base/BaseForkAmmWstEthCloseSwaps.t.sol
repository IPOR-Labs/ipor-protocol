// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/console2.sol";
import "./BaseTestForkCommons.sol";
import {IAmmCloseSwapServiceWstEth} from "../../contracts/interfaces/IAmmCloseSwapServiceWstEth.sol";
import {AmmTypes} from "../../contracts/interfaces/types/AmmTypes.sol";
import {AmmStorageBaseV1} from "../../contracts/base/amm/AmmStorageBaseV1.sol";
import {IAmmPoolsServiceWstEthBaseV2} from "../../contracts/base/amm-wstEth/interfaces/IAmmPoolsServiceWstEthBaseV2.sol";

contract BaseForkAmmWstEthCloseSwapsTest is BaseTestForkCommons {
    function setUp() public {
        vm.createSelectFork(vm.envString("BASE_PROVIDER_URL"), 29096300);
    }

    function testShouldClosePositionWstEthForWstEth28daysPayFixed() public {
        //given
        _init();
        address user = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
        _setupUser(user, 1000 * 1e18);
        uint256 totalAmount = 1 * 1e17;

        vm.warp(block.timestamp);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 50000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            wstETH,
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed28daysWstEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        vm.warp(block.timestamp + 28 days + 1);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        //when
        vm.prank(user);
        IAmmCloseSwapServiceWstEth(iporProtocolRouterProxy).closeSwapsWstEth(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );

        //then
        AmmTypesBaseV1.Swap memory swap = AmmStorageBaseV1(ammStorageWstEthProxy).getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            swapId
        );

        assertEq(user, swap.buyer, "swap.buyer");
        assertEq(0, uint256(swap.state), "swap.state");
    }

    function testShouldDepositToAssetManagementWstEth() public {
        //given
        _init();
        _setupUser(owner, 1000 * 1e18);

        // Transfer wstETH from Lido treasury to owner
        vm.prank(0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb);
        IERC20(wstETH).transfer(owner, 1000 * 1e18);

        // First, transfer wstETH to the AMM treasury to ensure it has sufficient balance
        vm.prank(owner);
        IERC20(wstETH).transfer(ammTreasuryWstEthProxy, 100 * 1e18);

        uint256 assetManagementBalanceBefore = IERC4626(iporPlasmaVaultWstEth).totalAssets();

        // when
        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(wstETH, 100 * 1e18);

        //then
        uint256 assetManagementBalanceAfter = IERC4626(iporPlasmaVaultWstEth).totalAssets();

        assertGt(
            assetManagementBalanceAfter,
            assetManagementBalanceBefore,
            "Asset management balance should increase after deposit"
        );
    }

    function testShouldWithdrawFromAssetManagementWstEth() public {
        //given
        _init();
        _setupUser(owner, 1000 * 1e18);

        // Transfer wstETH from Lido treasury to owner
        vm.prank(0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb);
        IERC20(wstETH).transfer(owner, 1000 * 1e18);

        // First, transfer wstETH to the AMM treasury to ensure it has sufficient balance
        vm.prank(owner);
        IERC20(wstETH).transfer(ammTreasuryWstEthProxy, 100 * 1e18);

        // First deposit some wstETH to asset management
        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).depositToAssetManagement(wstETH, 100 * 1e18);

        vm.warp(block.timestamp + 1 seconds);

        uint256 assetManagementBalanceBefore = IERC4626(iporPlasmaVaultWstEth).totalAssets();

        // when
        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).withdrawFromAssetManagement(wstETH, 50 * 1e18);

        //then
        uint256 assetManagementBalanceAfter = IERC4626(iporPlasmaVaultWstEth).totalAssets();

        assertLt(
            assetManagementBalanceAfter,
            assetManagementBalanceBefore,
            "Asset management balance should decrease after withdrawal"
        );
    }

    function testShouldRebalanceBetweenAmmTreasuryAndAssetManagementWstEth() public {
        //given
        _init();

        // Record balances before rebalancing
        uint256 ammTreasuryBalanceBefore = IERC20(wstETH).balanceOf(ammTreasuryWstEthProxy);
        uint256 assetManagementBalanceBefore = IERC4626(iporPlasmaVaultWstEth).totalAssets();

        // Add the test contract as an appointed account to rebalance
        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).addAppointedToRebalanceInAmm(wstETH, address(this));

        // Set AMM pools parameters for rebalancing
        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(
            wstETH,
            1000000000, // maxLiquidityPoolBalance
            1, // autoRebalanceThreshold
            100 // ammTreasuryAssetManagementRatio (15%)
        );
        //when
        IAmmPoolsServiceWstEthBaseV2(iporProtocolRouterProxy).rebalanceBetweenAmmTreasuryAndAssetManagementWstEth();

        //then
        uint256 ammTreasuryBalanceAfter = IERC20(wstETH).balanceOf(ammTreasuryWstEthProxy);
        uint256 assetManagementBalanceAfter = IERC4626(iporPlasmaVaultWstEth).totalAssets();

        // Verify that the asset management (plasma vault) balance increased
        assertGt(
            assetManagementBalanceAfter,
            assetManagementBalanceBefore,
            "Asset management balance should be higher after rebalancing"
        );

        console2.log("assetManagementBalanceAfter", assetManagementBalanceAfter);
        console2.log("assetManagementBalanceBefore", assetManagementBalanceBefore);
    }
}
