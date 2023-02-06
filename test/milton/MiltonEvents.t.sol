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
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
    }

    function testShouldEmitEventWhenOpenPayFixedSwap18Decimals() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC); // 4%
        MockTestnetToken daiMockedToken = getTokenDai();
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IpToken ipTokenDai = getIpTokenDai(address(daiMockedToken));
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai miltonDai = getMockCase0MiltonDai(
            address(daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai josephDai = getMockCase0JosephDai(
            address(daiMockedToken),
            address(ipTokenDai),
            address(miltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, daiMockedToken, address(josephDai), address(miltonDai));
        prepareMilton(miltonDai, address(josephDai), address(stanleyDai));
        prepareJoseph(josephDai);
        prepareIpToken(ipTokenDai, address(josephDai));
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp); // 3%, PERCENTAGE_3_18DEC
        vm.prank(_liquidityProvider);
        josephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp);
        // when
        vm.prank(_userTwo);
        vm.expectEmit(true, true, true, true);
        emit OpenSwap(
            1, // swapId
            _userTwo, // buyer
            address(daiMockedToken), // asset
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
        miltonDai.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            TestConstants.USD_10_000_18DEC, // totalAmount
            TestConstants.PERCENTAGE_6_18DEC, // acceptableFixedInterestRate, 6%
            TestConstants.LEVERAGE_18DEC // leverage, LEVERAGE_18DEC
        );
    }

    function testShouldEmitEventWhenOpenReceiveFixedSwap18Decimals() public {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC); // 2%
        MockTestnetToken daiMockedToken = getTokenDai();
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IpToken ipTokenDai = getIpTokenDai(address(daiMockedToken));
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai miltonDai = getMockCase0MiltonDai(
            address(daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai josephDai = getMockCase0JosephDai(
            address(daiMockedToken),
            address(ipTokenDai),
            address(miltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, daiMockedToken, address(josephDai), address(miltonDai));
        prepareMilton(miltonDai, address(josephDai), address(stanleyDai));
        prepareJoseph(josephDai);
        prepareIpToken(ipTokenDai, address(josephDai));
        // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(daiMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp); // 3%, PERCENTAGE_3_18DEC
        vm.prank(_liquidityProvider);
        josephDai.itfProvideLiquidity(TestConstants.USD_28_000_18DEC, block.timestamp); // TestConstants.USD_28_000_18DEC
        vm.prank(_userTwo);
        vm.expectEmit(true, true, true, true);
        emit OpenSwap(
            1, // swapId
            _userTwo, // buyer
            address(daiMockedToken), // asset
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
        miltonDai.itfOpenSwapReceiveFixed(
            block.timestamp, // openTimestamp
            TestConstants.USD_10_000_18DEC, // totalAmount
            TestConstants.PERCENTAGE_1_18DEC, // acceptableFixedInterestRate, 1%
            TestConstants.LEVERAGE_18DEC // leverage
        );
    }

    function testShouldEmitEventWhenOpenPayFixedSwap6Decimals() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_4_18DEC); // 4%
        MockTestnetToken usdtMockedToken = getTokenUsdt();
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(usdtMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IpToken ipTokenUsdt = getIpTokenUsdt(address(usdtMockedToken));
        MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt miltonUsdt = getMockCase0MiltonUsdt(
            address(usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt josephUsdt = getMockCase0JosephUsdt(
            address(usdtMockedToken),
            address(ipTokenUsdt),
            address(miltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, usdtMockedToken, address(josephUsdt), address(miltonUsdt));
        prepareMilton(miltonUsdt, address(josephUsdt), address(stanleyUsdt));
        prepareJoseph(josephUsdt);
        prepareIpToken(ipTokenUsdt, address(josephUsdt));
        // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp); // 3%, PERCENTAGE_3_18DEC
        vm.prank(_liquidityProvider);
        josephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp);
        vm.prank(_userTwo);
        vm.expectEmit(true, true, true, true);
        emit OpenSwap(
            1, // swapId
            _userTwo, // buyer
            address(usdtMockedToken), // asset
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
        miltonUsdt.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            TestConstants.USD_10_000_6DEC, // totalAmount
            TestConstants.PERCENTAGE_6_18DEC, // acceptableFixedInterestRate, 6%
            TestConstants.LEVERAGE_18DEC // leverage
        );
    }

    function testShouldEmitEventWhenOpenReceiveFixedSwap6Decimals() public {
        // given
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(TestConstants.PERCENTAGE_2_18DEC); // 2%
        MockTestnetToken usdtMockedToken = getTokenUsdt();
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(usdtMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IpToken ipTokenUsdt = getIpTokenUsdt(address(usdtMockedToken));
        MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt miltonUsdt = getMockCase0MiltonUsdt(
            address(usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt josephUsdt = getMockCase0JosephUsdt(
            address(usdtMockedToken),
            address(ipTokenUsdt),
            address(miltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, usdtMockedToken, address(josephUsdt), address(miltonUsdt));
        prepareMilton(miltonUsdt, address(josephUsdt), address(stanleyUsdt));
        prepareJoseph(josephUsdt);
        prepareIpToken(ipTokenUsdt, address(josephUsdt));
        // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(usdtMockedToken), TestConstants.PERCENTAGE_3_18DEC, block.timestamp); // 3%, PERCENTAGE_3_18DEC
        vm.prank(_liquidityProvider);
        josephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp); // USD_28_000_6DEC
        vm.prank(_userTwo);
        vm.expectEmit(true, true, true, true);
        emit OpenSwap(
            1, // swapId
            _userTwo, // buyer
            address(usdtMockedToken), // asset
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
        miltonUsdt.itfOpenSwapReceiveFixed(
            block.timestamp, // openTimestamp
            TestConstants.USD_10_000_6DEC, // totalAmount
            TestConstants.PERCENTAGE_1_18DEC, // acceptableFixedInterestRate, 1%
            TestConstants.LEVERAGE_18DEC // leverage
        );
    }

    function testShouldEmitEventWhenClosePayFixedSwap18Decimals() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC); // 6%
        MockTestnetToken daiMockedToken = getTokenDai();
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(daiMockedToken), 5e16);
        IpToken ipTokenDai = getIpTokenDai(address(daiMockedToken));
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai miltonDai = getMockCase0MiltonDai(
            address(daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai josephDai = getMockCase0JosephDai(
            address(daiMockedToken),
            address(ipTokenDai),
            address(miltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, daiMockedToken, address(josephDai), address(miltonDai));
        prepareMilton(miltonDai, address(josephDai), address(stanleyDai));
        prepareJoseph(josephDai);
        prepareIpToken(ipTokenDai, address(josephDai));
        // when
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
        vm.expectEmit(true, true, true, true);
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

    function testShouldEmitEventWhenClosePayFixedSwap6DecimalsAndTakerClosedSwap() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC); // 6%
        MockTestnetToken usdtMockedToken = getTokenUsdt();
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(usdtMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IpToken ipTokenUsdt = getIpTokenUsdt(address(usdtMockedToken));
        MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt miltonUsdt = getMockCase0MiltonUsdt(
            address(usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt josephUsdt = getMockCase0JosephUsdt(
            address(usdtMockedToken),
            address(ipTokenUsdt),
            address(miltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, usdtMockedToken, address(josephUsdt), address(miltonUsdt));
        prepareMilton(miltonUsdt, address(josephUsdt), address(stanleyUsdt));
        prepareJoseph(josephUsdt);
        prepareIpToken(ipTokenUsdt, address(josephUsdt));
        // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        josephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp); // USD_28_000_6DEC
        vm.prank(_userTwo);
        miltonUsdt.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            TestConstants.USD_10_000_6DEC, // totalAmount, USD_10_000_6DEC
            TestConstants.PERCENTAGE_6_18DEC, // acceptableFixedInterestRate, 6%
            TestConstants.LEVERAGE_18DEC // leverage
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(usdtMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp); // PERCENTAGE_160_18DEC
        vm.prank(_userTwo);
        vm.expectEmit(true, true, true, true);
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

    function testShouldEmitEventWhenClosePayFixedSwap6DecimalsAndNotTakerClosedSwap() public {
        // given
        _miltonSpreadModel.setCalculateQuotePayFixed(TestConstants.PERCENTAGE_6_18DEC); // 6%
        MockTestnetToken usdtMockedToken = getTokenUsdt();
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(usdtMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        IpToken ipTokenUsdt = getIpTokenUsdt(address(usdtMockedToken));
        MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt miltonUsdt = getMockCase0MiltonUsdt(
            address(usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt josephUsdt = getMockCase0JosephUsdt(
            address(usdtMockedToken),
            address(ipTokenUsdt),
            address(miltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(_users, usdtMockedToken, address(josephUsdt), address(miltonUsdt));
        prepareMilton(miltonUsdt, address(josephUsdt), address(stanleyUsdt));
        prepareJoseph(josephUsdt);
        prepareIpToken(ipTokenUsdt, address(josephUsdt));
        // when
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(usdtMockedToken), TestConstants.PERCENTAGE_5_18DEC, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        josephUsdt.itfProvideLiquidity(TestConstants.USD_28_000_6DEC, block.timestamp); // USD_28_000_6DEC
        vm.prank(_userTwo);
        miltonUsdt.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            TestConstants.USD_10_000_6DEC, // totalAmount, USD_10_000_6DEC
            TestConstants.PERCENTAGE_6_18DEC, // acceptableFixedInterestRate, 6%
            TestConstants.LEVERAGE_18DEC // leverage, LEVERAGE_18DEC
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(usdtMockedToken), TestConstants.PERCENTAGE_160_18DEC, block.timestamp); // PERCENTAGE_160_18DEC
        vm.prank(_userThree);
        vm.expectEmit(true, true, true, true);
        emit CloseSwap(
            1, // swapId
            address(usdtMockedToken), // asset
            block.timestamp + TestConstants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // closeTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
            _userThree, // liquidator
            18937318804000000000000, // transferredToBuyer
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
        MockTestnetToken daiMockedToken = getTokenDai();
        ItfIporOracle iporOracle = getIporOracleAsset(_userOne, address(daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai miltonDai = getMockCase0MiltonDai(
            address(daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        address oldMiltonSpreadModel = miltonDai.getMiltonSpreadModel();
        address newMiltonSpreadModel = address(_userThree);
        // when
        vm.expectEmit(true, true, true, true);
        emit MiltonSpreadModelChanged(_admin, oldMiltonSpreadModel, newMiltonSpreadModel);
        miltonDai.setMiltonSpreadModel(newMiltonSpreadModel);
    }
}