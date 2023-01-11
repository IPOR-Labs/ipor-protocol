// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {MiltonUtils} from "../utils/MiltonUtils.sol";
import {MiltonStorageUtils} from "../utils/MiltonStorageUtils.sol";
import {JosephUtils} from "../utils/JosephUtils.sol";
import {StanleyUtils} from "../utils/StanleyUtils.sol";
import {IporOracleUtils} from "../utils/IporOracleUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/itf/ItfJosephUsdt.sol";
import "../../contracts/itf/ItfJosephDai.sol";
import "../../contracts/itf/ItfMiltonUsdt.sol";
import "../../contracts/itf/ItfMiltonDai.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenUsdt.sol";
import "../../contracts/mocks/tokens/MockTestnetTokenDai.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/interfaces/types/MiltonTypes.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";

contract MiltonEventsTest is
    Test,
    TestCommons,
    MiltonUtils,
    JosephUtils,
    MiltonStorageUtils,
    IporOracleUtils,
    DataUtils,
    StanleyUtils
{
    MockSpreadModel internal _miltonSpreadModel;
    address internal _admin;
    address internal _userOne;
    address internal _userTwo;
    address internal _userThree;
    address internal _liquidityProvider;

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
        address indexed changedBy, address indexed oldMiltonSpreadModel, address indexed newMiltonSpreadModel
    );

    function setUp() public {
        _miltonSpreadModel = prepareMockSpreadModel(
            TestConstants.ZERO, TestConstants.ZERO, TestConstants.ZERO_INT, TestConstants.ZERO_INT
        );
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
    }

    function testShouldEmitEventWhenOpenPayFixedSwap18Decimals() public {
        // given
        MockTestnetTokenDai daiMockedToken = getTokenDai();
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(daiMockedToken), 0);
        IpToken ipTokenDai = getIpTokenDai(address(daiMockedToken));
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        ItfMiltonDai miltonDai = getItfMiltonDai(
            address(daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        ItfJosephDai josephDai = getItfJosephDai(
            address(daiMockedToken),
            address(ipTokenDai),
            address(miltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, daiMockedToken, address(josephDai), address(miltonDai));
        prepareMiltonStorage(miltonStorageDai, address(josephDai), address(miltonDai));
        prepareItfMiltonDai(miltonDai, address(josephDai), address(stanleyDai));
        prepareItfJosephDai(josephDai);
        prepareIpTokenDai(ipTokenDai, address(josephDai));
        // when
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC); // 4%
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp); // 3%, PERCENTAGE_3_18DEC
        vm.prank(_liquidityProvider);
        josephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        vm.prank(_userTwo);
        vm.expectEmit(true, true, false, false);
        emit OpenSwap(
            1, // swapId
            _userTwo, // buyer
            address(daiMockedToken), // asset
            MiltonTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING, // direction
            AmmTypes.OpenSwapMoney({
                totalAmount: TestConstants.USD_10_000_18DEC, // totalAmount
                collateral: TestConstants.TC_COLLATERAL_18DEC, // collateral
                notional: 99670098970308907327800, // notional
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
                ibtQuantity: 99670098970308907327800, // ibtQuantity
                fixedInterestRate: TestConstants.PERCENTAGE_4_18DEC // fixedInterestRate, 4%
            }) // indicator
        );
        miltonDai.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            TestConstants.USD_10_000_18DEC, // totalAmount
            TestConstants.PERCENTAGE_6_18DEC, // acceptableFixedInterestRate, 6%
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC // leverage, LEVERAGE_18DEC
        );
    }

    function testShouldEmitEventWhenOpenReceiveFixedSwap18Decimals() public {
        // given
        MockTestnetTokenDai daiMockedToken = getTokenDai();
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(daiMockedToken), 0);
        IpToken ipTokenDai = getIpTokenDai(address(daiMockedToken));
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        ItfMiltonDai miltonDai = getItfMiltonDai(
            address(daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        ItfJosephDai josephDai = getItfJosephDai(
            address(daiMockedToken),
            address(ipTokenDai),
            address(miltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, daiMockedToken, address(josephDai), address(miltonDai));
        prepareMiltonStorage(miltonStorageDai, address(josephDai), address(miltonDai));
        prepareItfMiltonDai(miltonDai, address(josephDai), address(stanleyDai));
        prepareItfJosephDai(josephDai);
        prepareIpTokenDai(ipTokenDai, address(josephDai));
        // when
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC); // 2%
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp); // 3%, PERCENTAGE_3_18DEC
        vm.prank(_liquidityProvider);
        josephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp); // TestConstants.USD_28_000_18DEC
        vm.prank(_userTwo);
        vm.expectEmit(true, true, false, false);
        emit OpenSwap(
            1, // swapId
            _userTwo, // buyer
            address(daiMockedToken), // asset
            MiltonTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED, // direction
            AmmTypes.OpenSwapMoney({
                totalAmount: TestConstants.USD_10_000_18DEC, // totalAmount
                collateral: TestConstants.TC_COLLATERAL_18DEC, // collateral
                notional: 99670098970308907327800, // notional
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
                ibtQuantity: 99670098970308907327800, // ibtQuantity
                fixedInterestRate: TestConstants.PERCENTAGE_2_18DEC // fixedInterestRate, 2%
            }) // indicator
        );
        miltonDai.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            TestConstants.USD_10_000_18DEC, // totalAmount
            TestConstants.PERCENTAGE_1_18DEC, // acceptableFixedInterestRate, 1%
            TestConstants.LEVERAGE_18DEC // leverage
        );
    }

    function testShouldEmitEventWhenOpenPayFixedSwap6Decimals() public {
        // given
        MockTestnetTokenUsdt usdtMockedToken = getTokenUsdt();
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(usdtMockedToken), 0);
        IpToken ipTokenUsdt = getIpTokenUsdt(address(usdtMockedToken));
        MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        ItfMiltonUsdt miltonUsdt = getItfMiltonUsdt(
            address(usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        ItfJosephUsdt josephUsdt = getItfJosephUsdt(
            address(usdtMockedToken),
            address(ipTokenUsdt),
            address(miltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersUsdt(users, usdtMockedToken, address(josephUsdt), address(miltonUsdt));
        prepareMiltonStorage(miltonStorageUsdt, address(josephUsdt), address(miltonUsdt));
        prepareItfMiltonUsdt(miltonUsdt, address(josephUsdt), address(stanleyUsdt));
        prepareItfJosephUsdt(josephUsdt);
        prepareIpTokenUsdt(ipTokenUsdt, address(josephUsdt));
        // when
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC); // 4%
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp); // 3%, PERCENTAGE_3_18DEC
        vm.prank(_liquidityProvider);
        josephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);
        vm.prank(_userTwo);
        vm.expectEmit(true, true, false, false);
        emit OpenSwap(
            1, // swapId
            _userTwo, // buyer
            address(usdtMockedToken), // asset
            MiltonTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING, // direction
            AmmTypes.OpenSwapMoney({
                totalAmount: TestConstants.USD_10_000_18DEC, // totalAmount
                collateral: TestConstants.TC_COLLATERAL_18DEC, // collateral
                notional: 99670098970308907327800, // notional
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
                ibtQuantity: 99670098970308907327800, // ibtQuantity
                fixedInterestRate: TestConstants.PERCENTAGE_4_18DEC // fixedInterestRate, 4%
            }) // indicator
        );
        miltonUsdt.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            TestConstants.USD_10_000_6DEC, // totalAmount
            TestConstants.PERCENTAGE_6_18DEC, // acceptableFixedInterestRate, 6%
            TestConstants.LEVERAGE_18DEC // leverage
        );
    }

    function testShouldEmitEventWhenOpenReceiveFixedSwap6Decimals() public {
        // given
        MockTestnetTokenUsdt usdtMockedToken = getTokenUsdt();
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(usdtMockedToken), 0);
        IpToken ipTokenUsdt = getIpTokenUsdt(address(usdtMockedToken));
        MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        ItfMiltonUsdt miltonUsdt = getItfMiltonUsdt(
            address(usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        ItfJosephUsdt josephUsdt = getItfJosephUsdt(
            address(usdtMockedToken),
            address(ipTokenUsdt),
            address(miltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersUsdt(users, usdtMockedToken, address(josephUsdt), address(miltonUsdt));
        prepareMiltonStorage(miltonStorageUsdt, address(josephUsdt), address(miltonUsdt));
        prepareItfMiltonUsdt(miltonUsdt, address(josephUsdt), address(stanleyUsdt));
        prepareItfJosephUsdt(josephUsdt);
        prepareIpTokenUsdt(ipTokenUsdt, address(josephUsdt));
        // when
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC); // 2%
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp); // 3%, PERCENTAGE_3_18DEC
        vm.prank(_liquidityProvider);
        josephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp); // USD_28_000_6DEC
        vm.prank(_userTwo);
        vm.expectEmit(true, true, false, false);
        emit OpenSwap(
            1, // swapId
            _userTwo, // buyer
            address(usdtMockedToken), // asset
            MiltonTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED, // direction
            AmmTypes.OpenSwapMoney({
                totalAmount: TestConstants.USD_10_000_18DEC, // totalAmount
                collateral: TestConstants.TC_COLLATERAL_18DEC, // collateral
                notional: 99670098970308907327800, // notional
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
                ibtQuantity: 99670098970308907327800, // ibtQuantity
                fixedInterestRate: TestConstants.PERCENTAGE_2_18DEC // fixedInterestRate, 2%
            }) // indicator
        );
        miltonUsdt.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            TestConstants.USD_10_000_6DEC, // totalAmount
            TestConstants.PERCENTAGE_1_18DEC, // acceptableFixedInterestRate, 1%
            TestConstants.LEVERAGE_18DEC // leverage
        );
    }

    function testShouldEmitEventWhenClosePayFixedSwap18Decimals() public {
        // given
        MockTestnetTokenDai daiMockedToken = getTokenDai();
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(daiMockedToken), 0);
        IpToken ipTokenDai = getIpTokenDai(address(daiMockedToken));
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        ItfMiltonDai miltonDai = getItfMiltonDai(
            address(daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        ItfJosephDai josephDai = getItfJosephDai(
            address(daiMockedToken),
            address(ipTokenDai),
            address(miltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, daiMockedToken, address(josephDai), address(miltonDai));
        prepareMiltonStorage(miltonStorageDai, address(josephDai), address(miltonDai));
        prepareItfMiltonDai(miltonDai, address(josephDai), address(stanleyDai));
        prepareItfJosephDai(josephDai);
        prepareIpTokenDai(ipTokenDai, address(josephDai));
        // when
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC); // 6%
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(daiMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        josephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp); // TestConstants.USD_28_000_18DEC
        vm.prank(_userTwo);
        miltonDai.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            TestConstants.USD_10_000_18DEC, // totalAmount
            TestConstants.PERCENTAGE_6_18DEC, // acceptableFixedInterestRate, 6%
            TestConstants.LEVERAGE_18DEC // leverage
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(daiMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp); // PERCENTAGE_160_18DEC
        vm.prank(_userTwo);
        vm.expectEmit(true, true, false, false);
        emit CloseSwap(
            1, // swapId
            address(daiMockedToken), // asset
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // closeTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
            _userTwo, // liquidator
            18957318804358692392282, // transferredToBuyer
            TestConstants.ZERO, // transferredToLiquidator
            TestConstants.TC_INCOME_TAX_18DEC // incomeFeeValue
        );
        miltonDai.itfCloseSwapPayFixed(
            1, // swapId
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS // closeTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
        );
    }

    function testShouldEmitEventWhenClosePayFixedSwap6Decimals() public {
        // given
        MockTestnetTokenUsdt usdtMockedToken = getTokenUsdt();
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(usdtMockedToken), 0);
        IpToken ipTokenUsdt = getIpTokenUsdt(address(usdtMockedToken));
        MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        ItfMiltonUsdt miltonUsdt = getItfMiltonUsdt(
            address(usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        ItfJosephUsdt josephUsdt = getItfJosephUsdt(
            address(usdtMockedToken),
            address(ipTokenUsdt),
            address(miltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersUsdt(users, usdtMockedToken, address(josephUsdt), address(miltonUsdt));
        prepareMiltonStorage(miltonStorageUsdt, address(josephUsdt), address(miltonUsdt));
        prepareItfMiltonUsdt(miltonUsdt, address(josephUsdt), address(stanleyUsdt));
        prepareItfJosephUsdt(josephUsdt);
        prepareIpTokenUsdt(ipTokenUsdt, address(josephUsdt));
        // when
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC); // 6%
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        josephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp); // USD_28_000_6DEC
        vm.prank(_userTwo);
        miltonUsdt.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            TestConstants.USD_10_000_6DEC, // totalAmount, USD_10_000_6DEC
            TestConstants.PERCENTAGE_6_18DEC, // acceptableFixedInterestRate, 6%
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC // leverage
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(usdtMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp); // PERCENTAGE_160_18DEC
        vm.prank(_userTwo);
        vm.expectEmit(true, true, false, false);
        emit CloseSwap(
            1, // swapId
            address(usdtMockedToken), // asset
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // closeTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
            _userTwo, // liquidator
            18957318804000000000000, // transferredToBuyer
            TestConstants.ZERO, // transferredToLiquidator
            TestConstants.TC_INCOME_TAX_18DEC // incomeFeeValue
        );
        miltonUsdt.itfCloseSwapPayFixed(
            1, // swapId
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS // closeTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
        );
    }

    function testShouldEmitEventWhenClosePayFixedSwap6DecimalsNotTakerClosedSwap() public {
        // given
        MockTestnetTokenUsdt usdtMockedToken = getTokenUsdt();
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(usdtMockedToken), 0);
        IpToken ipTokenUsdt = getIpTokenUsdt(address(usdtMockedToken));
        MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        ItfMiltonUsdt miltonUsdt = getItfMiltonUsdt(
            address(usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        ItfJosephUsdt josephUsdt = getItfJosephUsdt(
            address(usdtMockedToken),
            address(ipTokenUsdt),
            address(miltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersUsdt(users, usdtMockedToken, address(josephUsdt), address(miltonUsdt));
        prepareMiltonStorage(miltonStorageUsdt, address(josephUsdt), address(miltonUsdt));
        prepareItfMiltonUsdt(miltonUsdt, address(josephUsdt), address(stanleyUsdt));
        prepareItfJosephUsdt(josephUsdt);
        prepareIpTokenUsdt(ipTokenUsdt, address(josephUsdt));
        // when
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC); // 6%
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        josephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp); // USD_28_000_6DEC
        vm.prank(_userTwo);
        miltonUsdt.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            TestConstants.USD_10_000_6DEC, // totalAmount, USD_10_000_6DEC
            TestConstants.PERCENTAGE_6_18DEC, // acceptableFixedInterestRate, 6%
            TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC // leverage, LEVERAGE_18DEC
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(usdtMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp); // PERCENTAGE_160_18DEC
        vm.prank(_userThree);
        vm.expectEmit(true, true, false, false);
        emit CloseSwap(
            1, // swapId
            address(usdtMockedToken), // asset
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // closeTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
            _userThree, // liquidator
            18957318804000000000000, // transferredToBuyer
            TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC, // transferredToLiquidator
            TestConstants.TC_INCOME_TAX_18DEC // incomeFeeValue
        );
        miltonUsdt.itfCloseSwapPayFixed(
            1, // swapId
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS // closeTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
        );
    }

    function testShouldEmitMiltonSpreadModelChanged() public {
        // given
        MockTestnetTokenDai daiMockedToken = getTokenDai();
        ItfIporOracle iporOracle = getIporOracleOneAsset(_userOne, address(daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        ItfMiltonDai miltonDai = getItfMiltonDai(
            address(daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        address oldMiltonSpreadModel = miltonDai.getMiltonSpreadModel();
        address newMiltonSpreadModel = address(_userThree);
        // when
        vm.expectEmit(true, true, true, false);
        emit MiltonSpreadModelChanged(_admin, oldMiltonSpreadModel, newMiltonSpreadModel);
        miltonDai.setMiltonSpreadModel(newMiltonSpreadModel);
    }
}
