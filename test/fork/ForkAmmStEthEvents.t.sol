// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./TestForkCommons.sol";
import "../../contracts/interfaces/IAmmCloseSwapServiceStEth.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";

contract ForkAmmStEthEventsTest is TestForkCommons {
    struct OpenSwapAmount {
        uint256 accountInputTokenAmount;
        uint256 totalAmount;
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
        address accountInputToken,
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
        vm.createSelectFork(vm.envString("PROVIDER_URL"), 18562032);
    }

    //
    //    function testShouldContainAccountInputTokenInEventWhenOpenPositionStEthForEth28daysPayFixed() public {
    //        //given
    //        _init();
    //        address user = _getUserAddress(22);
    //        _setupUser(user, 1000 * 1e18);
    //
    //        uint256 totalAmount = 1e17;
    //
    //        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
    //            maxCollateralRatio: 50000000000000000,
    //            maxCollateralRatioPerLeg: 50000000000000000,
    //            maxLeveragePerLeg: 1000000000000000000000,
    //            baseSpreadPerLeg: 3695000000000000,
    //            fixedRateCapPerLeg: 20000000000000000,
    //            demandSpreadFactor: 20,
    //            expiration: block.timestamp + 1000,
    //            signature: bytes("0x00")
    //        });
    //
    //        riskIndicatorsInputs.signature = signRiskParams(
    //            riskIndicatorsInputs,
    //            address(stETH),
    //            uint256(IporTypes.SwapTenor.DAYS_28),
    //            0,
    //            messageSignerPrivateKey
    //        );
    //
    //        address expectedAccountInputToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    //        uint256 expectedAccountInputTokenAmount = 100000000000000000;
    //
    //        vm.prank(user);
    //        //then
    //        vm.expectEmit(true, true, true, true);
    //        emit OpenSwap({
    //            swapId: 1,
    //            buyer: 0x37dA28C050E3c0A1c0aC3BE97913EC038783dA4C,
    //            accountInputToken: expectedAccountInputToken,
    //            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
    //            direction: AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
    //            amounts: OpenSwapAmount({
    //                accountInputTokenAmount: expectedAccountInputTokenAmount,
    //                totalAmount: 100000000000000000,
    //                collateral: 89965492687736186,
    //                notional: 899654926877361860,
    //                openingFeeLPAmount: 17253656131894,
    //                openingFeeTreasuryAmount: 17253656131895,
    //                iporPublicationFee: 10000000000000000,
    //                liquidationDepositAmount: 25000000000000000000
    //            }),
    //            openTimestamp: 1699867019,
    //            endTimestamp: 1702286219,
    //            indicator: IporSwapIndicator({
    //                iporIndexValue: 0,
    //                ibtPrice: 1000000000000000000,
    //                ibtQuantity: 899654926877361860,
    //                fixedInterestRate: 20000699314353823
    //            })
    //        });
    //        //when
    //        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth{
    //            value: totalAmount
    //        }(ETH, user, totalAmount, 1e18, 10e18, riskIndicatorsInputs);
    //    }
    //
    //    function testShouldContainAccountInputTokenInEventWhenOpenPositionStEthForStEth28daysPayFixed() public {
    //        //given
    //        _init();
    //        address user = _getUserAddress(22);
    //        _setupUser(user, 1000 * 1e18);
    //
    //        uint256 totalAmount = 1e17;
    //
    //        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
    //            maxCollateralRatio: 50000000000000000,
    //            maxCollateralRatioPerLeg: 50000000000000000,
    //            maxLeveragePerLeg: 1000000000000000000000,
    //            baseSpreadPerLeg: 3695000000000000,
    //            fixedRateCapPerLeg: 20000000000000000,
    //            demandSpreadFactor: 20,
    //            expiration: block.timestamp + 1000,
    //            signature: bytes("0x00")
    //        });
    //
    //        riskIndicatorsInputs.signature = signRiskParams(
    //            riskIndicatorsInputs,
    //            address(stETH),
    //            uint256(IporTypes.SwapTenor.DAYS_28),
    //            0,
    //            messageSignerPrivateKey
    //        );
    //
    //        address expectedAccountInputToken = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    //        uint256 expectedAccountInputTokenAmount = 100000000000000000;
    //
    //        vm.prank(user);
    //        //then
    //        vm.expectEmit(true, true, true, true);
    //        emit OpenSwap({
    //            swapId: 1,
    //            buyer: 0x37dA28C050E3c0A1c0aC3BE97913EC038783dA4C,
    //            accountInputToken: expectedAccountInputToken,
    //            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
    //            direction: AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
    //            amounts: OpenSwapAmount({
    //                accountInputTokenAmount: expectedAccountInputTokenAmount,
    //                totalAmount: 100000000000000000,
    //                collateral: 89965492687736186,
    //                notional: 899654926877361860,
    //                openingFeeLPAmount: 17253656131894,
    //                openingFeeTreasuryAmount: 17253656131895,
    //                iporPublicationFee: 10000000000000000,
    //                liquidationDepositAmount: 25000000000000000000
    //            }),
    //            openTimestamp: 1699867019,
    //            endTimestamp: 1702286219,
    //            indicator: IporSwapIndicator({
    //                iporIndexValue: 0,
    //                ibtPrice: 1000000000000000000,
    //                ibtQuantity: 899654926877361860,
    //                fixedInterestRate: 20000699314353823
    //            })
    //        });
    //        //when
    //        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth(
    //            stETH,
    //            user,
    //            totalAmount,
    //            1e18,
    //            10e18,
    //            riskIndicatorsInputs
    //        );
    //    }
    //
    //    function testShouldContainAccountInputTokenInEventWhenOpenPositionStEthForWEth28daysPayFixed() public {
    //        //given
    //        _init();
    //        address user = _getUserAddress(22);
    //        _setupUser(user, 1000 * 1e18);
    //
    //        uint256 totalAmount = 1e17;
    //
    //        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
    //            maxCollateralRatio: 50000000000000000,
    //            maxCollateralRatioPerLeg: 50000000000000000,
    //            maxLeveragePerLeg: 1000000000000000000000,
    //            baseSpreadPerLeg: 3695000000000000,
    //            fixedRateCapPerLeg: 20000000000000000,
    //            demandSpreadFactor: 20,
    //            expiration: block.timestamp + 1000,
    //            signature: bytes("0x00")
    //        });
    //
    //        riskIndicatorsInputs.signature = signRiskParams(
    //            riskIndicatorsInputs,
    //            address(stETH),
    //            uint256(IporTypes.SwapTenor.DAYS_28),
    //            0,
    //            messageSignerPrivateKey
    //        );
    //
    //        address expectedAccountInputToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    //        uint256 expectedAccountInputTokenAmount = 100000000000000000;
    //
    //        vm.prank(user);
    //        //then
    //        vm.expectEmit(true, true, true, true);
    //        emit OpenSwap({
    //            swapId: 1,
    //            buyer: 0x37dA28C050E3c0A1c0aC3BE97913EC038783dA4C,
    //            accountInputToken: expectedAccountInputToken,
    //            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
    //            direction: AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
    //            amounts: OpenSwapAmount({
    //                accountInputTokenAmount: expectedAccountInputTokenAmount,
    //                totalAmount: 100000000000000000,
    //                collateral: 89965492687736186,
    //                notional: 899654926877361860,
    //                openingFeeLPAmount: 17253656131894,
    //                openingFeeTreasuryAmount: 17253656131895,
    //                iporPublicationFee: 10000000000000000,
    //                liquidationDepositAmount: 25000000000000000000
    //            }),
    //            openTimestamp: 1699867019,
    //            endTimestamp: 1702286219,
    //            indicator: IporSwapIndicator({
    //                iporIndexValue: 0,
    //                ibtPrice: 1000000000000000000,
    //                ibtQuantity: 899654926877361860,
    //                fixedInterestRate: 20000699314353823
    //            })
    //        });
    //        //when
    //        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth(
    //            wETH,
    //            user,
    //            totalAmount,
    //            1e18,
    //            10e18,
    //            riskIndicatorsInputs
    //        );
    //    }
    //
    //    function testShouldContainAccountInputTokenInEventWhenOpenPositionStEthForwstEth28daysPayFixed() public {
    //        //given
    //        _init();
    //        address user = _getUserAddress(22);
    //        _setupUser(user, 1000 * 1e18);
    //
    //        uint256 totalAmount = 1e17;
    //
    //        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
    //            maxCollateralRatio: 50000000000000000,
    //            maxCollateralRatioPerLeg: 50000000000000000,
    //            maxLeveragePerLeg: 1000000000000000000000,
    //            baseSpreadPerLeg: 3695000000000000,
    //            fixedRateCapPerLeg: 20000000000000000,
    //            demandSpreadFactor: 20,
    //            expiration: block.timestamp + 1000,
    //            signature: bytes("0x00")
    //        });
    //
    //        riskIndicatorsInputs.signature = signRiskParams(
    //            riskIndicatorsInputs,
    //            address(stETH),
    //            uint256(IporTypes.SwapTenor.DAYS_28),
    //            0,
    //            messageSignerPrivateKey
    //        );
    //
    //        address expectedAccountInputToken = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    //        uint256 expectedAccountInputTokenAmount = 87235841251539969;
    //
    //        vm.prank(user);
    //        //then
    //        vm.expectEmit(true, true, true, true);
    //        emit OpenSwap({
    //            swapId: 1,
    //            buyer: 0x37dA28C050E3c0A1c0aC3BE97913EC038783dA4C,
    //            accountInputToken: expectedAccountInputToken,
    //            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
    //            direction: AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
    //            amounts: OpenSwapAmount({
    //                accountInputTokenAmount: expectedAccountInputTokenAmount,
    //                totalAmount: 100000000000000000,
    //                collateral: 89965492687736186,
    //                notional: 899654926877361860,
    //                openingFeeLPAmount: 17253656131894,
    //                openingFeeTreasuryAmount: 17253656131895,
    //                iporPublicationFee: 10000000000000000,
    //                liquidationDepositAmount: 25000000000000000000
    //            }),
    //            openTimestamp: 1699867019,
    //            endTimestamp: 1702286219,
    //            indicator: IporSwapIndicator({
    //                iporIndexValue: 0,
    //                ibtPrice: 1000000000000000000,
    //                ibtQuantity: 899654926877361860,
    //                fixedInterestRate: 20000699314353823
    //            })
    //        });
    //        //when
    //        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed28daysStEth(
    //            wstETH,
    //            user,
    //            totalAmount,
    //            1e18,
    //            10e18,
    //            riskIndicatorsInputs
    //        );
    //    }
    //
    //    function testShouldContainAccountInputTokenInEventWhenOpenPositionStEthForEth28daysReceiveFixed() public {
    //        //given
    //        _init();
    //        address user = _getUserAddress(22);
    //        _setupUser(user, 1000 * 1e18);
    //
    //        uint256 totalAmount = 1e17;
    //
    //        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
    //            maxCollateralRatio: 50000000000000000,
    //            maxCollateralRatioPerLeg: 50000000000000000,
    //            maxLeveragePerLeg: 1000000000000000000000,
    //            baseSpreadPerLeg: 3695000000000000,
    //            fixedRateCapPerLeg: 20000000000000000,
    //            demandSpreadFactor: 20,
    //            expiration: block.timestamp + 1000,
    //            signature: bytes("0x00")
    //        });
    //
    //        riskIndicatorsInputs.signature = signRiskParams(
    //            riskIndicatorsInputs,
    //            address(stETH),
    //            uint256(IporTypes.SwapTenor.DAYS_28),
    //            1,
    //            messageSignerPrivateKey
    //        );
    //
    //        address expectedAccountInputToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    //        uint256 expectedAccountInputTokenAmount = 100000000000000000;
    //
    //        vm.prank(user);
    //        //then
    //        vm.expectEmit(true, true, true, true);
    //        emit OpenSwap({
    //            swapId: 1,
    //            buyer: 0x37dA28C050E3c0A1c0aC3BE97913EC038783dA4C,
    //            accountInputToken: expectedAccountInputToken,
    //            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
    //            direction: AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
    //            amounts: OpenSwapAmount({
    //                accountInputTokenAmount: expectedAccountInputTokenAmount,
    //                totalAmount: 100000000000000000,
    //                collateral: 89965492687736186,
    //                notional: 899654926877361860,
    //                openingFeeLPAmount: 17253656131894,
    //                openingFeeTreasuryAmount: 17253656131895,
    //                iporPublicationFee: 10000000000000000,
    //                liquidationDepositAmount: 25000000000000000000
    //            }),
    //            openTimestamp: 1699867019,
    //            endTimestamp: 1702286219,
    //            indicator: IporSwapIndicator({
    //                iporIndexValue: 0,
    //                ibtPrice: 1000000000000000000,
    //                ibtQuantity: 899654926877361860,
    //                fixedInterestRate: 3694300685646177
    //            })
    //        });
    //        //when
    //        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysStEth{
    //            value: totalAmount
    //        }(ETH, user, totalAmount, 0, 10e18, riskIndicatorsInputs);
    //    }
    //
    //    function testShouldContainAccountInputTokenInEventWhenOpenPositionStEthForStEth28daysReceiveFixed() public {
    //        //given
    //        _init();
    //        address user = _getUserAddress(22);
    //        _setupUser(user, 1000 * 1e18);
    //
    //        uint256 totalAmount = 1e17;
    //
    //        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
    //            maxCollateralRatio: 50000000000000000,
    //            maxCollateralRatioPerLeg: 50000000000000000,
    //            maxLeveragePerLeg: 1000000000000000000000,
    //            baseSpreadPerLeg: 3695000000000000,
    //            fixedRateCapPerLeg: 20000000000000000,
    //            demandSpreadFactor: 20,
    //            expiration: block.timestamp + 1000,
    //            signature: bytes("0x00")
    //        });
    //
    //        riskIndicatorsInputs.signature = signRiskParams(
    //            riskIndicatorsInputs,
    //            address(stETH),
    //            uint256(IporTypes.SwapTenor.DAYS_28),
    //            1,
    //            messageSignerPrivateKey
    //        );
    //
    //        address expectedAccountInputToken = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    //        uint256 expectedAccountInputTokenAmount = 100000000000000000;
    //
    //        vm.prank(user);
    //        //then
    //        vm.expectEmit(true, true, true, true);
    //        emit OpenSwap({
    //            swapId: 1,
    //            buyer: 0x37dA28C050E3c0A1c0aC3BE97913EC038783dA4C,
    //            accountInputToken: expectedAccountInputToken,
    //            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
    //            direction: AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
    //            amounts: OpenSwapAmount({
    //                accountInputTokenAmount: expectedAccountInputTokenAmount,
    //                totalAmount: 100000000000000000,
    //                collateral: 89965492687736186,
    //                notional: 899654926877361860,
    //                openingFeeLPAmount: 17253656131894,
    //                openingFeeTreasuryAmount: 17253656131895,
    //                iporPublicationFee: 10000000000000000,
    //                liquidationDepositAmount: 25000000000000000000
    //            }),
    //            openTimestamp: 1699867019,
    //            endTimestamp: 1702286219,
    //            indicator: IporSwapIndicator({
    //                iporIndexValue: 0,
    //                ibtPrice: 1000000000000000000,
    //                ibtQuantity: 899654926877361860,
    //                fixedInterestRate: 3694300685646177
    //            })
    //        });
    //        //when
    //        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysStEth(
    //            stETH,
    //            user,
    //            totalAmount,
    //            0,
    //            10e18,
    //            riskIndicatorsInputs
    //        );
    //    }
    //
    //    function testShouldContainAccountInputTokenInEventWhenOpenPositionStEthForWEth28daysReceiveFixed() public {
    //        //given
    //        _init();
    //        address user = _getUserAddress(22);
    //        _setupUser(user, 1000 * 1e18);
    //
    //        uint256 totalAmount = 1e17;
    //
    //        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
    //            maxCollateralRatio: 50000000000000000,
    //            maxCollateralRatioPerLeg: 50000000000000000,
    //            maxLeveragePerLeg: 1000000000000000000000,
    //            baseSpreadPerLeg: 3695000000000000,
    //            fixedRateCapPerLeg: 20000000000000000,
    //            demandSpreadFactor: 20,
    //            expiration: block.timestamp + 1000,
    //            signature: bytes("0x00")
    //        });
    //
    //        riskIndicatorsInputs.signature = signRiskParams(
    //            riskIndicatorsInputs,
    //            address(stETH),
    //            uint256(IporTypes.SwapTenor.DAYS_28),
    //            1,
    //            messageSignerPrivateKey
    //        );
    //
    //        address expectedAccountInputToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    //        uint256 expectedAccountInputTokenAmount = 100000000000000000;
    //
    //        vm.prank(user);
    //        //then
    //        vm.expectEmit(true, true, true, true);
    //        emit OpenSwap({
    //            swapId: 1,
    //            buyer: 0x37dA28C050E3c0A1c0aC3BE97913EC038783dA4C,
    //            accountInputToken: expectedAccountInputToken,
    //            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
    //            direction: AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
    //            amounts: OpenSwapAmount({
    //                accountInputTokenAmount: expectedAccountInputTokenAmount,
    //                totalAmount: 100000000000000000,
    //                collateral: 89965492687736186,
    //                notional: 899654926877361860,
    //                openingFeeLPAmount: 17253656131894,
    //                openingFeeTreasuryAmount: 17253656131895,
    //                iporPublicationFee: 10000000000000000,
    //                liquidationDepositAmount: 25000000000000000000
    //            }),
    //            openTimestamp: 1699867019,
    //            endTimestamp: 1702286219,
    //            indicator: IporSwapIndicator({
    //                iporIndexValue: 0,
    //                ibtPrice: 1000000000000000000,
    //                ibtQuantity: 899654926877361860,
    //                fixedInterestRate: 3694300685646177
    //            })
    //        });
    //        //when
    //        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysStEth(
    //            wETH,
    //            user,
    //            totalAmount,
    //            0,
    //            10e18,
    //            riskIndicatorsInputs
    //        );
    //    }
    //
    //    function testShouldContainAccountInputTokenInEventWhenOpenPositionStEthForwstEth28daysReceiveFixed() public {
    //        //given
    //        _init();
    //        address user = _getUserAddress(22);
    //        _setupUser(user, 1000 * 1e18);
    //
    //        uint256 totalAmount = 1e17;
    //
    //        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
    //            maxCollateralRatio: 50000000000000000,
    //            maxCollateralRatioPerLeg: 50000000000000000,
    //            maxLeveragePerLeg: 1000000000000000000000,
    //            baseSpreadPerLeg: 3695000000000000,
    //            fixedRateCapPerLeg: 20000000000000000,
    //            demandSpreadFactor: 20,
    //            expiration: block.timestamp + 1000,
    //            signature: bytes("0x00")
    //        });
    //
    //        riskIndicatorsInputs.signature = signRiskParams(
    //            riskIndicatorsInputs,
    //            address(stETH),
    //            uint256(IporTypes.SwapTenor.DAYS_28),
    //            1,
    //            messageSignerPrivateKey
    //        );
    //
    //        address expectedAccountInputToken = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    //        uint256 expectedAccountInputTokenAmount = 87235841251539969;
    //
    //        vm.prank(user);
    //        //then
    //        vm.expectEmit(true, true, true, true);
    //        emit OpenSwap({
    //            swapId: 1,
    //            buyer: 0x37dA28C050E3c0A1c0aC3BE97913EC038783dA4C,
    //            accountInputToken: expectedAccountInputToken,
    //            asset: 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84,
    //            direction: AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
    //            amounts: OpenSwapAmount({
    //                accountInputTokenAmount: expectedAccountInputTokenAmount,
    //                totalAmount: 100000000000000000,
    //                collateral: 89965492687736186,
    //                notional: 899654926877361860,
    //                openingFeeLPAmount: 17253656131894,
    //                openingFeeTreasuryAmount: 17253656131895,
    //                iporPublicationFee: 10000000000000000,
    //                liquidationDepositAmount: 25000000000000000000
    //            }),
    //            openTimestamp: 1699867019,
    //            endTimestamp: 1702286219,
    //            indicator: IporSwapIndicator({
    //                iporIndexValue: 0,
    //                ibtPrice: 1000000000000000000,
    //                ibtQuantity: 899654926877361860,
    //                fixedInterestRate: 3694300685646177
    //            })
    //        });
    //        //when
    //        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed28daysStEth(
    //            wstETH,
    //            user,
    //            totalAmount,
    //            0,
    //            10e18,
    //            riskIndicatorsInputs
    //        );
    //    }

    function testShouldSendCorrectEventCloseSwapWhenClosePositionStEthForStEth60daysPayFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            0,
            messageSignerPrivateKey
        );
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed60daysStEth(
            stETH,
            user,
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

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).addSwapLiquidator(stETH, liquidator);

        vm.warp(block.timestamp + 60 days);
        //when
        vm.prank(liquidator);

        vm.expectEmit(true, true, true, true);
        emit CloseSwap({
            swapId: 1,
            asset: stETH,
            closeTimestamp: 1705051019,
            liquidator: liquidator,
            transferredToBuyer: 86964645057802772,
            transferredToLiquidator: 25000000000000000000
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            1,
            messageSignerPrivateKey
        );
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysStEth(
            stETH,
            user,
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

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).addSwapLiquidator(stETH, liquidator);

        vm.warp(block.timestamp + 60 days);
        //when
        vm.prank(liquidator);

        vm.expectEmit(true, true, true, true);
        emit CloseSwap({
            swapId: 1,
            asset: stETH,
            closeTimestamp: 1705051019,
            liquidator: liquidator,
            transferredToBuyer: 90472359266062921,
            transferredToLiquidator: 25000000000000000000
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            liquidator,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldSendCorrectEventCloseSwapWhenClosePositionStEthForWEth60daysPayFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            0,
            messageSignerPrivateKey
        );
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed60daysStEth(
            wETH,
            user,
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

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).addSwapLiquidator(stETH, liquidator);

        vm.warp(block.timestamp + 60 days);
        //when
        vm.prank(liquidator);

        vm.expectEmit(true, true, true, true);
        emit CloseSwap({
            swapId: 1,
            asset: stETH,
            closeTimestamp: 1705051019,
            liquidator: liquidator,
            transferredToBuyer: 86964645057802772,
            transferredToLiquidator: 25000000000000000000
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            liquidator,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldSendCorrectEventCloseSwapWhenClosePositionStEthForWEth60daysReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            1,
            messageSignerPrivateKey
        );
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysStEth(
            wETH,
            user,
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

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).addSwapLiquidator(stETH, liquidator);

        vm.warp(block.timestamp + 60 days);
        //when
        vm.prank(liquidator);

        vm.expectEmit(true, true, true, true);
        emit CloseSwap({
            swapId: 1,
            asset: stETH,
            closeTimestamp: 1705051019,
            liquidator: liquidator,
            transferredToBuyer: 90472359266062921,
            transferredToLiquidator: 25000000000000000000
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            liquidator,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldSendCorrectEventCloseSwapWhenClosePositionStEthForEth60daysPayFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            0,
            messageSignerPrivateKey
        );
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed60daysStEth{
            value: totalAmount
        }(ETH, user, totalAmount, 1e18, 10e18, riskIndicatorsInputs);

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = swapId;
        uint256[] memory swapRfIds = new uint256[](0);

        AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs = _prepareCloseSwapRiskIndicators(
            IporTypes.SwapTenor.DAYS_60
        );

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).addSwapLiquidator(stETH, liquidator);

        vm.warp(block.timestamp + 60 days);
        //when
        vm.prank(liquidator);

        vm.expectEmit(true, true, true, true);
        emit CloseSwap({
            swapId: 1,
            asset: stETH,
            closeTimestamp: 1705051019,
            liquidator: liquidator,
            transferredToBuyer: 86964645057802772,
            transferredToLiquidator: 25000000000000000000
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            liquidator,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldSendCorrectEventCloseSwapWhenClosePositionStEthForEth60daysReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            1,
            messageSignerPrivateKey
        );
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysStEth{value:totalAmount}(
            ETH,
            user,
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

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).addSwapLiquidator(stETH, liquidator);

        vm.warp(block.timestamp + 60 days);
        //when
        vm.prank(liquidator);

        vm.expectEmit(true, true, true, true);
        emit CloseSwap({
            swapId: 1,
            asset: stETH,
            closeTimestamp: 1705051019,
            liquidator: liquidator,
            transferredToBuyer: 90472359266062921,
            transferredToLiquidator: 25000000000000000000
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            liquidator,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldSendCorrectEventCloseSwapWhenClosePositionStEthForwstEth60daysPayFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            0,
            messageSignerPrivateKey
        );
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapPayFixed60daysStEth(
            wstETH,
            user,
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

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).addSwapLiquidator(stETH, liquidator);

        vm.warp(block.timestamp + 60 days);
        //when
        vm.prank(liquidator);

        vm.expectEmit(true, true, true, true);
        emit CloseSwap({
            swapId: 1,
            asset: stETH,
            closeTimestamp: 1705051019,
            liquidator: liquidator,
            transferredToBuyer: 86964645057802772,
            transferredToLiquidator: 25000000000000000000
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            liquidator,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }

    function testShouldSendCorrectEventCloseSwapWhenClosePositionStEthForwstEth60daysReceiveFixed() public {
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
            address(stETH),
            uint256(IporTypes.SwapTenor.DAYS_60),
            1,
            messageSignerPrivateKey
        );
        vm.prank(user);
        uint256 swapId = IAmmOpenSwapServiceStEth(iporProtocolRouterProxy).openSwapReceiveFixed60daysStEth(
            wstETH,
            user,
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

        vm.prank(owner);
        IAmmGovernanceService(iporProtocolRouterProxy).addSwapLiquidator(stETH, liquidator);

        vm.warp(block.timestamp + 60 days);
        //when
        vm.prank(liquidator);

        vm.expectEmit(true, true, true, true);
        emit CloseSwap({
            swapId: 1,
            asset: stETH,
            closeTimestamp: 1705051019,
            liquidator: liquidator,
            transferredToBuyer: 90472359266062921,
            transferredToLiquidator: 25000000000000000000
        });
        IAmmCloseSwapServiceStEth(iporProtocolRouterProxy).closeSwapsStEth(
            liquidator,
            swapPfIds,
            swapRfIds,
            closeRiskIndicatorsInputs
        );
    }
}
