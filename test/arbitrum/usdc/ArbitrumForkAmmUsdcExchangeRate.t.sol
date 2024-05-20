// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/console2.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./UsdcTestForkCommonArbitrum.sol";
import {IAmmOpenSwapServiceUsdc} from "../../../contracts/chains/arbitrum/interfaces/IAmmOpenSwapServiceUsdc.sol";
import {IAmmCloseSwapServiceUsdc} from "../../../contracts/interfaces/IAmmCloseSwapServiceUsdc.sol";

import "../../../contracts/interfaces/types/AmmTypes.sol";

contract ArbitrumForkAmmUsdcExchangeRateTest is UsdcTestForkCommonArbitrum {
    uint256 public constant T_ASSET_DECIMALS = 1e6;

    function testShouldNotChangeExchangeRateWhenProvideLiquidityUsdcForUsdc() public {
        // given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * T_ASSET_DECIMALS);

        uint256 provideAmount = 1e6;

        uint256 exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(USDC);

        // when
        vm.prank(user);
        IAmmPoolsServiceUsdc(iporProtocolRouterProxy).provideLiquidityUsdcToAmmPoolUsdc(user, provideAmount);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(USDC);

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenProvideLiquidityAndRedeemBecauseOfRedeemFeeUsdcForUsdc() public {
        // given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * T_ASSET_DECIMALS);

        uint256 provideAmount = 1e6;

        uint256 exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(USDC);

        // when
        vm.startPrank(user);
        IAmmPoolsServiceUsdc(iporProtocolRouterProxy).provideLiquidityUsdcToAmmPoolUsdc(user, provideAmount);
        uint256 ipUSDCAmount = IERC20(ipUsdc).balanceOf(user);
        IAmmPoolsServiceUsdc(iporProtocolRouterProxy).redeemFromAmmPoolUsdc(user, ipUSDCAmount);
        vm.stopPrank();

        //then
        uint256 exchangeRateAfter = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(USDC);

        assertLt(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNOTChangeExchangeRateWhenProvideLiquidityAndRedeemBecauseOfRedeemFeeIsZEROUsdcForUsdc()
    public
    {
        // given
        _init();
        _createNewAmmPoolsServiceUsdcWithZEROFee();
        _setupAssetServices();

        address user = _getUserAddress(22);
        _setupUser(user, 1000 * T_ASSET_DECIMALS);

        uint256 provideAmount = 1e6;

        uint256 exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(USDC);

        // when
        vm.startPrank(user);
        IAmmPoolsServiceUsdc(iporProtocolRouterProxy).provideLiquidityUsdcToAmmPoolUsdc(user, provideAmount);

        uint256 ipUSDCAmount = IERC20(ipUsdc).balanceOf(user);
        IAmmPoolsServiceUsdc(iporProtocolRouterProxy).redeemFromAmmPoolUsdc(user, ipUSDCAmount);
        vm.stopPrank();

        //then
        uint256 exchangeRateAfter = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(USDC);

        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldChangeExchangeRateWhenOpenBecauseOpeningFeeSwap28daysUsdc() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * T_ASSET_DECIMALS);

        uint256 totalAmount = 1e5;

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
            USDC,
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        uint256 exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(USDC);

        //when
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapPayFixed28daysUsdc(
            user,
            USDC,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        //then
        uint256 exchangeRateAfter = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(USDC);

        assertNotEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }


    function testShouldNotChangeExchangeRateWhenChangeStorageBalancePublicationFee() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * T_ASSET_DECIMALS);
        uint256 totalAmount = 1 * 1e5;

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
            USDC,
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapPayFixed28daysUsdc(
            user,
            USDC,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        vm.warp(block.timestamp + 1 days + 1);
        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        vm.prank(user);
        IAmmCloseSwapServiceUsdc(iporProtocolRouterProxy).closeSwapsUsdc(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
        AmmTypesBaseV1.Balance memory balance = AmmStorageBaseV1(ammStorageUsdcProxy).getBalance();
        uint256 exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(USDC);

        uint256 balancePublicationFeeBefore = AmmStorageBaseV1(ammStorageUsdcProxy).getBalance().iporPublicationFee;

        //when
        vm.prank(treasurer);
        IAmmGovernanceService(iporProtocolRouterProxy).transferToCharlieTreasury(USDC, balancePublicationFeeBefore);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(USDC);
        uint256 balancePublicationFeeAfter = AmmStorageBaseV1(ammStorageUsdcProxy).getBalance().iporPublicationFee;

        assertEq(balancePublicationFeeAfter, 0, "iporPublicationFee after");
        assertGt(balancePublicationFeeBefore, 0, "iporPublicationFee before");
        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

    function testShouldNotChangeExchangeRateWhenChangeStorageBalanceDAOTreasury() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * T_ASSET_DECIMALS);
        uint256 totalAmount = 1 * 1e5;

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
            USDC,
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            messageSignerPrivateKey
        );

        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceUsdc(iporProtocolRouterProxy).openSwapPayFixed28daysUsdc(
            user,
            USDC,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        vm.warp(block.timestamp + 1 days + 1);
        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_28
        );

        vm.prank(user);
        IAmmCloseSwapServiceUsdc(iporProtocolRouterProxy).closeSwapsUsdc(
            user,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
        AmmTypesBaseV1.Balance memory balance = AmmStorageBaseV1(ammStorageUsdcProxy).getBalance();
        uint256 exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(USDC);

        uint256 balanceTreasuryBefore = AmmStorageBaseV1(ammStorageUsdcProxy).getBalance().treasury;

        //when
        vm.prank(treasurer);
        IAmmGovernanceService(iporProtocolRouterProxy).transferToTreasury(USDC, balanceTreasuryBefore);

        //then
        uint256 exchangeRateAfter = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(USDC);

        uint256 balanceTreasuryAfter = AmmStorageBaseV1(ammStorageUsdcProxy).getBalance().treasury;

        /// @dev when asset has lower decimal than 18, we need to use assertApproxEqAbs because of the precision
        assertApproxEqAbs(balanceTreasuryAfter, 0, 1e11, "iporPublicationFee after");

        assertGt(balanceTreasuryBefore, 0, "iporPublicationFee before");
        assertEq(exchangeRateBefore, exchangeRateAfter, "Exchange rate should not change");
    }

}
