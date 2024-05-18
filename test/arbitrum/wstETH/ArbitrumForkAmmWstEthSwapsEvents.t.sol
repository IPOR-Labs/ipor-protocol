// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../ArbitrumTestForkCommons.sol";
import "../../../contracts/interfaces/IAmmCloseSwapServiceWstEth.sol";
import "../../../contracts/interfaces/types/AmmTypes.sol";

contract ArbitrumForkAmmWstEthSwapsEventsTest is ArbitrumTestForkCommons {
    struct OpenSwapAmount {
        uint256 inputAssetTotalAmount;
        uint256 assetTotalAmount;
        uint256 collateral;
        uint256 notional;
        uint256 openingFeeLPAmount;
        uint256 openingFeeTreasuryAmount;
        uint256 iporPublicationFee;
        uint256 liquidationDepositAmount;
    }

    struct IporSwapIndicator {
        uint256 iporIndexValue;
        uint256 ibtPrice;
        uint256 ibtQuantity;
        uint256 fixedInterestRate;
    }

    event OpenSwap(
        uint256 indexed swapId,
        address indexed buyer,
        address inputAsset,
        address asset,
        AmmTypes.SwapDirection direction,
        OpenSwapAmount amounts,
        uint256 openTimestamp,
        uint256 endTimestamp,
        IporSwapIndicator indicator
    );

    event CloseSwap(
        uint256 indexed swapId,
        address asset,
        uint256 closeTimestamp,
        address liquidator,
        uint256 transferredToBuyer,
        uint256 transferredToLiquidator
    );

    function setUp() public {
        vm.createSelectFork(vm.envString("ARBITRUM_PROVIDER_URL"), 171764768);
    }
    
    function testShouldContainInputAssetInEventWhenOpenPositionWstEthForWstEth28daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 1e17;

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

        address expectedInputAsset = wstETH;
        uint256 expectedInputAssetAmount = 100000000000000000;

        vm.prank(user);
        //then
        vm.expectEmit(true, true, true, true);
        emit OpenSwap({
            swapId: 1,
            buyer: 0x37dA28C050E3c0A1c0aC3BE97913EC038783dA4C,
            inputAsset: expectedInputAsset,
            asset: wstETH,
            direction: AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            amounts: OpenSwapAmount({
                inputAssetTotalAmount: expectedInputAssetAmount,
                assetTotalAmount: 100000000000000000,
                collateral: 88965876102316920,
                notional: 889658761023169200,
                openingFeeLPAmount: 17061948841540,
                openingFeeTreasuryAmount: 17061948841540,
                iporPublicationFee: 10000000000000000,
                liquidationDepositAmount: 1000000000000000
            }),
            openTimestamp: 1705603684,
            endTimestamp: 1708022884,
            indicator: IporSwapIndicator({
                iporIndexValue: 0,
                ibtPrice: 1000000000000000000,
                ibtQuantity: 889658761023169200,
                fixedInterestRate: 20000115257294091
            })
        });
        //when
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed28daysWstEth(
            user,
            wstETH,
            totalAmount,
            1e18,
            10e18,
            riskIndicatorsInputs
        );
    }
    
    function testShouldContainInputAssetInEventWhenOpenPositionWstEthForWstEth28daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 1e17;

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
            1,
            messageSignerPrivateKey
        );

        address expectedInputAsset = wstETH;
        uint256 expectedInputAssetAmount = 100000000000000000;

        vm.prank(user);
        //then
        vm.expectEmit(true, true, true, true);
        emit OpenSwap({
            swapId: 1,
            buyer: 0x37dA28C050E3c0A1c0aC3BE97913EC038783dA4C,
            inputAsset: expectedInputAsset,
            asset: wstETH,
            direction: AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            amounts: OpenSwapAmount({
                inputAssetTotalAmount: expectedInputAssetAmount,
                assetTotalAmount: 100000000000000000,
                collateral: 88965876102316920,
                notional: 889658761023169200,
                openingFeeLPAmount: 17061948841540,
                openingFeeTreasuryAmount: 17061948841540,
                iporPublicationFee: 10000000000000000,
                liquidationDepositAmount: 1000000000000000
            }),
            openTimestamp: 1705603684,
            endTimestamp: 1708022884,
            indicator: IporSwapIndicator({
                iporIndexValue: 0,
                ibtPrice: 1000000000000000000,
                ibtQuantity: 889658761023169200,
                fixedInterestRate: 3694884742705909
            })
        });
        //when
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysWstEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );
    }
    
    function testShouldSendCorrectEventCloseSwapWhenClosePositionWstEthForWstEth60daysPayFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        address liquidator = _getUserAddress(23);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 1 * 1e17;

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
            uint256(IporTypes.SwapTenor.DAYS_60),
            0,
            messageSignerPrivateKey
        );
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapPayFixed60daysWstEth(
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

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_60
        );

        IAmmGovernanceService(iporProtocolRouterProxy).addSwapLiquidator(wstETH, liquidator);

        vm.warp(block.timestamp + 60 days);
        //when
        vm.prank(liquidator);

        vm.expectEmit(true, true, true, true);
        emit CloseSwap({
            swapId: 1,
            asset: wstETH,
            closeTimestamp: 1710787684,
            liquidator: liquidator,
            transferredToBuyer: 85998456845642692,
            transferredToLiquidator: 1000000000000000
        });

        IAmmCloseSwapServiceWstEth(iporProtocolRouterProxy).closeSwapsWstEth(
            liquidator,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldSendCorrectEventCloseSwapWhenClosePositionStEthForStEth60daysReceiveFixed() public {
        //given
        _init();
        address user = _getUserAddress(22);
        address liquidator = _getUserAddress(23);
        _setupUser(user, 1000 * 1e18);

        uint256 totalAmount = 1 * 1e17;

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
            uint256(IporTypes.SwapTenor.DAYS_60),
            1,
            messageSignerPrivateKey
        );
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceWstEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysWstEth(
            user,
            wstETH,
            totalAmount,
            0,
            10e18,
            riskIndicatorsInputs
        );

        uint256[] memory swapPfIds = new uint256[](0);
        uint256[] memory swapRfIds = new uint256[](1);
        swapRfIds[0] = swapId;

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_60
        );

        IAmmGovernanceService(iporProtocolRouterProxy).addSwapLiquidator(wstETH, liquidator);

        vm.warp(block.timestamp + 60 days);
        //when
        vm.prank(liquidator);

        vm.expectEmit(true, true, true, true);
        emit CloseSwap({
            swapId: 1,
            asset: wstETH,
            closeTimestamp: 1710787684,
            liquidator: liquidator,
            transferredToBuyer: 89467196222394761,
            transferredToLiquidator: 1000000000000000
        });
        IAmmCloseSwapServiceWstEth(iporProtocolRouterProxy).closeSwapsWstEth(
            liquidator,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }
}
