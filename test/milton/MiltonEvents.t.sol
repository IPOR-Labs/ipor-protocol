// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase0MiltonUsdt.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/interfaces/types/MiltonTypes.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";

contract MiltonEventsTest is Test, TestCommons, DataUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    IporProtocolBuilder.IporProtocol internal _iporProtocol;

    MockSpreadModel internal _miltonSpreadModel;

    /// @notice Emmited when trader opens new swap.
    /// @notice swap ID.
    event OpenSwap(
        uint256 indexed swapId,
        /// @notice trader that opened the swap
        address indexed buyer,
        /// @notice underlying asset
        address asset,
        /// @notice swap direction
        MiltonTypes.SwapDirection direction,
        /// @notice money structure related with this swap
        AmmTypes.OpenSwapMoney money,
        /// @notice the moment when swap was opened
        uint256 openTimestamp,
        /// @notice the moment when swap will achieve maturity
        uint256 endTimestamp,
        /// @notice attributes taken from IPOR Index indicators.
        MiltonTypes.IporSwapIndicator indicator
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
        /// @notice asset amount after closing swap that has been transferred from Milton to the Buyer. Value represented in 18 decimals.
        uint256 transferredToBuyer,
        /// @notice asset amount after closing swap that has been transferred from Milton to the Liquidator. Value represented in 18 decimals.
        uint256 transferredToLiquidator,
        /// @notice incomeFeeValue value transferred to treasury
        uint256 incomeFeeValue
    );

    event MiltonSpreadModelChanged(
        address indexed changedBy,
        address indexed oldMiltonSpreadModel,
        address indexed newMiltonSpreadModel
    );

    function setUp() public {
        _miltonSpreadModel = prepareMockSpreadModel(
            TestConstants.ZERO,
            TestConstants.ZERO,
            TestConstants.ZERO_INT,
            TestConstants.ZERO_INT
        );
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        _cfg.approvalsForUsers = _users;
        _cfg.iporOracleUpdater = _userOne;
        _cfg.iporRiskManagementOracleUpdater = _userOne;
    }

    function testShouldEmitEventWhenOpenPayFixedSwap18Decimals() public {
        // given
       _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );
        vm.prank(_liquidityProvider);

        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        // when
        vm.prank(_userTwo);
        vm.expectEmit(true, true, true, true);
        emit OpenSwap(
            1, // swapId
            _userTwo, // buyer
            address(_iporProtocol.asset), // asset
            MiltonTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING, // direction
            AmmTypes.OpenSwapMoney({
                totalAmount: TestConstants.USD_10_000_18DEC, // totalAmount
                collateral: TestConstants.TC_COLLATERAL_18DEC, // collateral
                notional: TestConstants.TC_NOTIONAL_18DEC, // notional
                openingFeeLPAmount: TestConstants.TC_OPENING_FEE_18DEC, // openingFeeLPAmount
                openingFeeTreasuryAmount: TestConstants.ZERO, // openingFeeTreasuryAmount
                iporPublicationFee: TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC, // iporPublicationFee
                liquidationDepositAmount: TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC // liquidationDepositAmount
            }), // money
            block.timestamp, // openTimestamp
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // endTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
            MiltonTypes.IporSwapIndicator({
                iporIndexValue: TestConstants.PERCENTAGE_3_18DEC, // iporIndexValue
                ibtPrice: 1 * TestConstants.D18, // ibtPrice
                ibtQuantity: TestConstants.TC_NOTIONAL_18DEC, // ibtQuantity
                fixedInterestRate: TestConstants.PERCENTAGE_4_18DEC // fixedInterestRate, 4%
            }) // indicator
        );

        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            TestConstants.USD_10_000_18DEC, // totalAmount
            TestConstants.PERCENTAGE_6_18DEC, // acceptableFixedInterestRate, 6%
            TestConstants.LEVERAGE_18DEC // leverage, LEVERAGE_18DEC
        );
    }

    function testShouldEmitEventWhenOpenReceiveFixedSwap18Decimals() public {
        // given
       _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);

        vm.prank(_userTwo);
        vm.expectEmit(true, true, true, true);
        emit OpenSwap(
            1, // swapId
            _userTwo, // buyer
            address(_iporProtocol.asset), // asset
            MiltonTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED, // direction
            AmmTypes.OpenSwapMoney({
                totalAmount: TestConstants.USD_10_000_18DEC, // totalAmount
                collateral: TestConstants.TC_COLLATERAL_18DEC, // collateral
                notional: TestConstants.TC_NOTIONAL_18DEC, // notional
                openingFeeLPAmount: TestConstants.TC_OPENING_FEE_18DEC, // openingFeeLPAmount
                openingFeeTreasuryAmount: TestConstants.ZERO, // openingFeeTreasuryAmount
                iporPublicationFee: TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC, // iporPublicationFee
                liquidationDepositAmount: TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC // liquidationDepositAmount
            }), // money
            block.timestamp, // openTimestamp
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // endTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
            MiltonTypes.IporSwapIndicator({
                iporIndexValue: TestConstants.PERCENTAGE_3_18DEC, // iporIndexValue
                ibtPrice: 1 * TestConstants.D18, // ibtPrice
                ibtQuantity: TestConstants.TC_NOTIONAL_18DEC, // ibtQuantity
                fixedInterestRate: TestConstants.PERCENTAGE_2_18DEC // fixedInterestRate, 2%
            }) // indicator
        );

        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp, // openTimestamp
            TestConstants.USD_10_000_18DEC, // totalAmount
            TestConstants.PERCENTAGE_1_18DEC, // acceptableFixedInterestRate, 1%
            TestConstants.LEVERAGE_18DEC // leverage
        );
    }

    function testShouldEmitEventWhenOpenPayFixedSwap6Decimals() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);

        vm.prank(_userTwo);
        vm.expectEmit(true, true, true, true);
        emit OpenSwap(
            1, // swapId
            _userTwo, // buyer
            address(_iporProtocol.asset), // asset
            MiltonTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING, // direction
            AmmTypes.OpenSwapMoney({
                totalAmount: TestConstants.USD_10_000_18DEC, // totalAmount
                collateral: TestConstants.TC_COLLATERAL_18DEC, // collateral
                notional: TestConstants.TC_NOTIONAL_18DEC, // notional
                openingFeeLPAmount: TestConstants.TC_OPENING_FEE_18DEC, // openingFeeLPAmount
                openingFeeTreasuryAmount: TestConstants.ZERO, // openingFeeTreasuryAmount
                iporPublicationFee: TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC, // iporPublicationFee
                liquidationDepositAmount: TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC // liquidationDepositAmount
            }), // money
            block.timestamp, // openTimestamp
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // endTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
            MiltonTypes.IporSwapIndicator({
                iporIndexValue: TestConstants.PERCENTAGE_3_18DEC, // iporIndexValue
                ibtPrice: 1 * TestConstants.D18, // ibtPrice
                ibtQuantity: TestConstants.TC_NOTIONAL_18DEC, // ibtQuantity
                fixedInterestRate: TestConstants.PERCENTAGE_4_18DEC // fixedInterestRate, 4%
            }) // indicator
        );

        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            TestConstants.USD_10_000_6DEC, // totalAmount
            TestConstants.PERCENTAGE_6_18DEC, // acceptableFixedInterestRate, 6%
            TestConstants.LEVERAGE_18DEC // leverage
        );
    }

    function testShouldEmitEventWhenOpenReceiveFixedSwap6Decimals() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        _iporProtocol.spreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp); // USD_28_000_6DEC

        vm.prank(_userTwo);
        vm.expectEmit(true, true, true, true);
        emit OpenSwap(
            1, // swapId
            _userTwo, // buyer
            address(_iporProtocol.asset), // asset
            MiltonTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED, // direction
            AmmTypes.OpenSwapMoney({
                totalAmount: TestConstants.USD_10_000_18DEC, // totalAmount
                collateral: TestConstants.TC_COLLATERAL_18DEC, // collateral
                notional: TestConstants.TC_NOTIONAL_18DEC, // notional
                openingFeeLPAmount: TestConstants.TC_OPENING_FEE_18DEC, // openingFeeLPAmount
                openingFeeTreasuryAmount: TestConstants.ZERO, // openingFeeTreasuryAmount
                iporPublicationFee: TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC, // iporPublicationFee
                liquidationDepositAmount: TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC // liquidationDepositAmount
            }), // money
            block.timestamp, // openTimestamp
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // endTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
            MiltonTypes.IporSwapIndicator({
                iporIndexValue: TestConstants.PERCENTAGE_3_18DEC, // iporIndexValue
                ibtPrice: 1 * TestConstants.D18, // ibtPrice
                ibtQuantity: TestConstants.TC_NOTIONAL_18DEC, // ibtQuantity
                fixedInterestRate: TestConstants.PERCENTAGE_2_18DEC // fixedInterestRate, 2%
            }) // indicator
        );

        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp, // openTimestamp
            TestConstants.USD_10_000_6DEC, // totalAmount
            TestConstants.PERCENTAGE_1_18DEC, // acceptableFixedInterestRate, 1%
            TestConstants.LEVERAGE_18DEC // leverage
        );
    }

    function testShouldEmitEventWhenClosePayFixedSwap18Decimals() public {
        // given
       _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp); // TestConstants.USD_28_000_18DEC

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            TestConstants.USD_10_000_18DEC, // totalAmount
            TestConstants.PERCENTAGE_6_18DEC, // acceptableFixedInterestRate, 6%
            TestConstants.LEVERAGE_18DEC // leverage
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        vm.expectEmit(true, true, true, true);
        emit CloseSwap(
            1, // swapId
            address(_iporProtocol.asset), // asset
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // closeTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
            _userTwo, // liquidator
            18957318804358692392282, // transferredToBuyer
            TestConstants.ZERO, // transferredToLiquidator
            TestConstants.TC_INCOME_TAX_18DEC // incomeFeeValue
        );

        _iporProtocol.milton.itfCloseSwapPayFixed(
            1, // swapId
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS // closeTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
        );
    }

    function testShouldEmitEventWhenClosePayFixedSwap6DecimalsAndTakerClosedSwap() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp); // USD_28_000_6DEC

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            TestConstants.USD_10_000_6DEC, // totalAmount, USD_10_000_6DEC
            TestConstants.PERCENTAGE_6_18DEC, // acceptableFixedInterestRate, 6%
            TestConstants.LEVERAGE_18DEC // leverage
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.prank(_userTwo);
        vm.expectEmit(true, true, true, true);
        emit CloseSwap(
            1, // swapId
            address(_iporProtocol.asset), // asset
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // closeTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
            _userTwo, // liquidator
            18957318804000000000000, // transferredToBuyer
            TestConstants.ZERO, // transferredToLiquidator
            TestConstants.TC_INCOME_TAX_18DEC // incomeFeeValue
        );

        _iporProtocol.milton.itfCloseSwapPayFixed(
            1, // swapId
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS // closeTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
        );
    }

    function testShouldEmitEventWhenClosePayFixedSwap6DecimalsAndNotTakerClosedSwap() public {
        // given
        _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        _iporProtocol.spreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC);

        _iporProtocol.milton.addSwapLiquidator(_userThree);

        // when
        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp); // USD_28_000_6DEC

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            TestConstants.USD_10_000_6DEC, // totalAmount, USD_10_000_6DEC
            TestConstants.PERCENTAGE_6_18DEC, // acceptableFixedInterestRate, 6%
            TestConstants.LEVERAGE_18DEC // leverage, LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_160_18DEC,
            block.timestamp
        );

        vm.prank(_userThree);
        vm.expectEmit(true, true, true, true);
        emit CloseSwap(
            1, // swapId
            address(_iporProtocol.asset), // asset
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // closeTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
            _userThree, // liquidator
            18937318804000000000000, // transferredToBuyer
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // transferredToLiquidator
            TestConstants.TC_INCOME_TAX_18DEC // incomeFeeValue
        );
        _iporProtocol.milton.itfCloseSwapPayFixed(
            1, // swapId
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS // closeTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
        );
    }

    function testShouldEmitMiltonSpreadModelChanged() public {
        // given
       _cfg.miltonTestCase = BuilderUtils.MiltonTestCase.CASE0;

        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        address oldMiltonSpreadModel = _iporProtocol.milton.getMiltonSpreadModel();
        address newMiltonSpreadModel = address(_userThree);

        // then
        vm.expectEmit(true, true, true, true);
        emit MiltonSpreadModelChanged(_admin, oldMiltonSpreadModel, newMiltonSpreadModel);
        // when
        _iporProtocol.milton.setMiltonSpreadModel(newMiltonSpreadModel);
    }
}
