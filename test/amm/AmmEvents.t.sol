// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";

contract AmmEventsTest is TestCommons {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    BuilderUtils.IporProtocol internal _iporProtocol;

    /// @notice Emmited when trader opens new swap.
    /// @notice swap ID.
    event OpenSwap(
        uint256 indexed swapId,
        /// @notice trader that opened the swap
        address indexed buyer,
        /// @notice underlying asset
        address asset,
        /// @notice swap direction
        AmmTypes.SwapDirection direction,
        /// @notice money structure related with this swap
        AmmTypes.OpenSwapAmount amounts,
        /// @notice the moment when swap was opened
        uint256 openTimestamp,
        /// @notice the moment when swap will achieve maturity
        uint256 endTimestamp,
        /// @notice attributes taken from IPOR Index indicators.
        AmmTypes.IporSwapIndicator indicator
    );

    /// @notice Emmited when trader closes Swap.
    /// @notice swap ID.
    event CloseSwap(
        uint256 indexed swapId,
        /// @notice underlying asset
        address asset,
        /// @notice the moment when swap was closed
        uint256 closeTimestamp,
        /// @notice account that liquidated the swap
        address liquidator,
        /// @notice asset amount after closing swap that has been transferred from AmmTreasury to the Buyer. Value represented in 18 decimals.
        uint256 transferredToBuyer,
        /// @notice asset amount after closing swap that has been transferred from AmmTreasury to the Liquidator. Value represented in 18 decimals.
        uint256 transferredToLiquidator
    );

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        _cfg.approvalsForUsers = _users;
        _cfg.iporOracleUpdater = _userOne;

        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE0;
        _cfg.openSwapServiceTestCase = BuilderUtils.AmmOpenSwapServiceTestCase.CASE1;
    }

    function testShouldEmitEventWhenOpenPayFixedSwap18Decimals() public {
        // given
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE1;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);
        vm.prank(_liquidityProvider);

        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        // when
        vm.prank(_userTwo);
        vm.expectEmit(true, true, true, true);
        emit OpenSwap({
            swapId: 1,
            buyer: _userTwo,
            asset: address(_iporProtocol.asset),
            direction: AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            amounts: AmmTypes.OpenSwapAmount({
                totalAmount: TestConstants.USD_10_000_18DEC,
                collateral: TestConstants.TC_COLLATERAL_18DEC,
                notional: TestConstants.TC_NOTIONAL_18DEC,
                openingFeeLPAmount: TestConstants.TC_OPENING_FEE_18DEC,
                openingFeeTreasuryAmount: TestConstants.ZERO,
                iporPublicationFee: TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC,
                liquidationDepositAmount: TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC
            }),
            openTimestamp: block.timestamp,
            endTimestamp: block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
            indicator: AmmTypes.IporSwapIndicator({
                iporIndexValue: TestConstants.PERCENTAGE_3_18DEC,
                ibtPrice: 1 * TestConstants.D18,
                ibtQuantity: TestConstants.TC_NOTIONAL_18DEC,
                fixedInterestRate: TestConstants.PERCENTAGE_4_18DEC
            })
        });

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 500,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            _iporProtocolFactory.messageSignerPrivateKey()
        );

        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.USD_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );
    }

    function testShouldEmitEventWhenOpenReceiveFixedSwap18Decimals() public {
        // given
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE2;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        vm.prank(_userTwo);
        vm.expectEmit(true, true, true, true);
        emit OpenSwap(
            1, // swapId
            _userTwo, // buyer
            address(_iporProtocol.asset), // asset
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED, // direction
            AmmTypes.OpenSwapAmount({
                totalAmount: TestConstants.USD_10_000_18DEC, // totalAmount
                collateral: TestConstants.TC_COLLATERAL_18DEC, // collateral
                notional: TestConstants.TC_NOTIONAL_18DEC, // notional
                openingFeeLPAmount: TestConstants.TC_OPENING_FEE_18DEC, // openingFeeLPAmount
                openingFeeTreasuryAmount: TestConstants.ZERO, // openingFeeTreasuryAmount
                iporPublicationFee: TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC,
                liquidationDepositAmount: TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC
            }),
            block.timestamp,
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
            AmmTypes.IporSwapIndicator({
                iporIndexValue: TestConstants.PERCENTAGE_3_18DEC,
                ibtPrice: 1 * TestConstants.D18,
                ibtQuantity: TestConstants.TC_NOTIONAL_18DEC,
                fixedInterestRate: TestConstants.PERCENTAGE_2_18DEC
            })
        );

        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            TestConstants.USD_10_000_18DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), 1)
        );
    }

    function testShouldEmitEventWhenOpenPayFixedSwap6Decimals() public {
        // given
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE1;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_28_000_6DEC);

        vm.prank(_userTwo);
        vm.expectEmit(true, true, true, true);
        emit OpenSwap(
            1, // swapId
            _userTwo, // buyer
            address(_iporProtocol.asset), // asset
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING, // direction
            AmmTypes.OpenSwapAmount({
                totalAmount: TestConstants.USD_10_000_18DEC, // totalAmount
                collateral: TestConstants.TC_COLLATERAL_18DEC, // collateral
                notional: TestConstants.TC_NOTIONAL_18DEC, // notional
                openingFeeLPAmount: TestConstants.TC_OPENING_FEE_18DEC, // openingFeeLPAmount
                openingFeeTreasuryAmount: TestConstants.ZERO, // openingFeeTreasuryAmount
                iporPublicationFee: TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC, // iporPublicationFee
                liquidationDepositAmount: TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC // liquidationDepositAmount
            }),
            block.timestamp, // openTimestamp
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // endTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
            AmmTypes.IporSwapIndicator({
                iporIndexValue: TestConstants.PERCENTAGE_3_18DEC, // iporIndexValue
                ibtPrice: 1 * TestConstants.D18, // ibtPrice
                ibtQuantity: TestConstants.TC_NOTIONAL_18DEC, // ibtQuantity
                fixedInterestRate: TestConstants.PERCENTAGE_4_18DEC // fixedInterestRate, 4%
            }) // indicator
        );

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 500,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            _iporProtocolFactory.messageSignerPrivateKey()
        );

        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _userTwo,
            TestConstants.USD_10_000_6DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );
    }

    function testShouldEmitEventWhenOpenReceiveFixedSwap6Decimals() public {
        // given
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE2;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_28_000_6DEC);

        vm.prank(_userTwo);
        vm.expectEmit(true, true, true, true);
        emit OpenSwap(
            1, // swapId
            _userTwo, // buyer
            address(_iporProtocol.asset), // asset
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED, // direction
            AmmTypes.OpenSwapAmount({
                totalAmount: TestConstants.USD_10_000_18DEC, // totalAmount
                collateral: TestConstants.TC_COLLATERAL_18DEC, // collateral
                notional: TestConstants.TC_NOTIONAL_18DEC, // notional
                openingFeeLPAmount: TestConstants.TC_OPENING_FEE_18DEC, // openingFeeLPAmount
                openingFeeTreasuryAmount: TestConstants.ZERO, // openingFeeTreasuryAmount
                iporPublicationFee: TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC, // iporPublicationFee
                liquidationDepositAmount: TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC // liquidationDepositAmount
            }),
            block.timestamp, // openTimestamp
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // endTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
            AmmTypes.IporSwapIndicator({
                iporIndexValue: TestConstants.PERCENTAGE_3_18DEC, // iporIndexValue
                ibtPrice: 1 * TestConstants.D18, // ibtPrice
                ibtQuantity: TestConstants.TC_NOTIONAL_18DEC, // ibtQuantity
                fixedInterestRate: TestConstants.PERCENTAGE_2_18DEC // fixedInterestRate, 2%
            }) // indicator
        );

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 500,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            1,
            _iporProtocolFactory.messageSignerPrivateKey()
        );

        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.USD_10_000_6DEC,
            TestConstants.PERCENTAGE_1_18DEC,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );
    }

    function testShouldEmitEventWhenClosePayFixedSwap18Decimals() public {
        // given

        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 500,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            _iporProtocolFactory.messageSignerPrivateKey()
        );

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.USD_10_000_18DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_160_18DEC);

        vm.prank(_userTwo);
        vm.expectEmit(true, true, true, true);
        emit CloseSwap(
            1,
            address(_iporProtocol.asset),
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
            _userTwo,
            19955412124333030204016,
            TestConstants.ZERO
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = 1;
        uint256[] memory swapRfIds = new uint256[](0);

        vm.warp(block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS);
        _iporProtocol.ammCloseSwapService.closeSwapsDai(_userTwo, swapPfIds, swapRfIds, getCloseRiskIndicatorsInputs(address(_iporProtocol.asset), IporTypes.SwapTenor.DAYS_28));
    }

    function testShouldEmitEventWhenClosePayFixedSwap6DecimalsAndTakerClosedSwap() public {
        // given
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_28_000_6DEC);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 500,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            _iporProtocolFactory.messageSignerPrivateKey()
        );

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _userTwo,
            TestConstants.USD_10_000_6DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_160_18DEC);

        vm.prank(_userTwo);
        vm.expectEmit(true, true, true, true);
        emit CloseSwap(
            1,
            address(_iporProtocol.asset),
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
            _userTwo,
            19955412124000000000000,
            TestConstants.ZERO
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = 1;
        uint256[] memory swapRfIds = new uint256[](0);

        vm.warp(block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS);
        _iporProtocol.ammCloseSwapService.closeSwapsUsdt(_userTwo, swapPfIds, swapRfIds, getCloseRiskIndicatorsInputs(address(_iporProtocol.asset), IporTypes.SwapTenor.DAYS_28));
    }

    function testShouldEmitEventWhenClosePayFixedSwap6DecimalsAndNotTakerClosedSwap() public {
        // given
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE3;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        _iporProtocol.ammGovernanceService.addSwapLiquidator(address(_iporProtocol.asset), _userThree);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_28_000_6DEC);

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputs = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 900000000000000000,
            maxCollateralRatioPerLeg: 480000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 1000000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 500,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputs.signature = signRiskParams(
            riskIndicatorsInputs,
            address(_iporProtocol.asset),
            uint256(IporTypes.SwapTenor.DAYS_28),
            0,
            _iporProtocolFactory.messageSignerPrivateKey()
        );

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _userTwo,
            TestConstants.USD_10_000_6DEC,
            TestConstants.PERCENTAGE_6_18DEC,
            TestConstants.LEVERAGE_18DEC,
            riskIndicatorsInputs
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_160_18DEC);

        vm.prank(_userThree);
        vm.expectEmit(true, true, true, true);

        emit CloseSwap(
            1,
            address(_iporProtocol.asset),
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS,
            _userThree,
            19935412124000000000000,
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC
        );

        uint256[] memory swapPfIds = new uint256[](1);
        swapPfIds[0] = 1;
        uint256[] memory swapRfIds = new uint256[](0);

        vm.warp(block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS);
        _iporProtocol.ammCloseSwapService.closeSwapsUsdt(_userThree, swapPfIds, swapRfIds, getCloseRiskIndicatorsInputs(address(_iporProtocol.asset), IporTypes.SwapTenor.DAYS_28));
    }
}
