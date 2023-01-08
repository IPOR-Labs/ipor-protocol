// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {ProxyTester} from "foundry-upgrades/ProxyTester.sol";
import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {MiltonUtils} from "../utils/MiltonUtils.sol";
import {MiltonStorageUtils} from "../utils/MiltonStorageUtils.sol";
import {JosephUtils} from "../utils/JosephUtils.sol";
import {StanleyUtils} from "../utils/StanleyUtils.sol";
import {IporOracleUtils} from "../utils/IporOracleUtils.sol";
import "../../contracts/libraries/Constants.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/itf/ItfJosephUsdt.sol";
import "../../contracts/itf/ItfJosephDai.sol";
import "../../contracts/itf/ItfMiltonUsdt.sol";
import "../../contracts/itf/ItfMiltonDai.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/UsdtMockedToken.sol";
import "../../contracts/mocks/tokens/DaiMockedToken.sol";
import "../../contracts/amm/MiltonStorage.sol";
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
        _miltonSpreadModel = prepareMockSpreadModel(0, 0, 0, 0);
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
    }

    function testShouldEmitEventWhenOpenPayFixedSwap18Decimals() public {
        // given
        DaiMockedToken daiMockedToken = getTokenDai();
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(daiMockedToken), 0);
        IpToken ipTokenDai = getIpTokenDai(address(daiMockedToken));
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester miltonDaiProxy, ItfMiltonDai miltonDai) = getItfMiltonDai(
            _admin,
            address(daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester josephDaiProxy, ItfJosephDai josephDai) = getItfJosephDai(
            _admin,
            address(daiMockedToken),
            address(ipTokenDai),
            address(miltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, daiMockedToken, address(josephDai), address(miltonDai));
        prepareMiltonStorage(miltonStorageDai, miltonStorageDaiProxy, address(josephDai), address(miltonDai));
        prepareItfMiltonDai(miltonDai, address(miltonDaiProxy), address(josephDai), address(stanleyDai));
        prepareItfJosephDai(josephDai, address(josephDaiProxy));
        prepareIpTokenDai(ipTokenDai, address(josephDai));
        // when
        _miltonSpreadModel.setCalculateQuotePayFixed(4 * 10 ** 16); // 4%
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(daiMockedToken), 3 * 10 ** 16, block.timestamp); // 3%, PERCENTAGE_3_18DEC
        vm.prank(_liquidityProvider);
        josephDai.itfProvideLiquidity(28000 * Constants.D18, block.timestamp); // USD_28_000_18DEC
        vm.prank(_userTwo);
        vm.expectEmit(true, true, false, false);
        emit OpenSwap(
            1, // swapId
            _userTwo, // buyer
            address(daiMockedToken), // asset
            MiltonTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING, // direction
            AmmTypes.OpenSwapMoney({
                totalAmount: 10000 * Constants.D18, // totalAmount
                collateral: 9967009897030890732780, // collateral
                notional: 99670098970308907327800, // notional
                openingFeeLPAmount: 2990102969109267220, // openingFeeLPAmount
                openingFeeTreasuryAmount: 0, // openingFeeTreasuryAmount
                iporPublicationFee: 10 * Constants.D18, // iporPublicationFee
                liquidationDepositAmount: 20 * Constants.D18 // liquidationDepositAmount
            }), // money
            block.timestamp, // openTimestamp
            block.timestamp + Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // endTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
            MiltonTypes.IporSwapIndicator({
                iporIndexValue: 3 * 10 ** 16, // iporIndexValue
                ibtPrice: 1 * Constants.D18, // ibtPrice
                ibtQuantity: 99670098970308907327800, // ibtQuantity
                fixedInterestRate: 4 * 10 ** 16 // fixedInterestRate, 4%
            }) // indicator
        );
        miltonDai.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            10000 * Constants.D18, // totalAmount
            6 * 10 ** 16, // acceptableFixedInterestRate, 6%
            10 * Constants.D18 // leverage, LEVERAGE_18DEC
        );
    }

    function testShouldEmitEventWhenOpenReceiveFixedSwap18Decimals() public {
        // given
        DaiMockedToken daiMockedToken = getTokenDai();
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(daiMockedToken), 0);
        IpToken ipTokenDai = getIpTokenDai(address(daiMockedToken));
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester miltonDaiProxy, ItfMiltonDai miltonDai) = getItfMiltonDai(
            _admin,
            address(daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester josephDaiProxy, ItfJosephDai josephDai) = getItfJosephDai(
            _admin,
            address(daiMockedToken),
            address(ipTokenDai),
            address(miltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, daiMockedToken, address(josephDai), address(miltonDai));
        prepareMiltonStorage(miltonStorageDai, miltonStorageDaiProxy, address(josephDai), address(miltonDai));
        prepareItfMiltonDai(miltonDai, address(miltonDaiProxy), address(josephDai), address(stanleyDai));
        prepareItfJosephDai(josephDai, address(josephDaiProxy));
        prepareIpTokenDai(ipTokenDai, address(josephDai));
        // when
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(2 * 10 ** 16); // 2%
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(daiMockedToken), 3 * 10 ** 16, block.timestamp); // 3%, PERCENTAGE_3_18DEC
        vm.prank(_liquidityProvider);
        josephDai.itfProvideLiquidity(28000 * Constants.D18, block.timestamp); // USD_28_000_18DEC
        vm.prank(_userTwo);
        vm.expectEmit(true, true, false, false);
        emit OpenSwap(
            1, // swapId
            _userTwo, // buyer
            address(daiMockedToken), // asset
            MiltonTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED, // direction
            AmmTypes.OpenSwapMoney({
                totalAmount: 10000 * Constants.D18, // totalAmount
                collateral: 9967009897030890732780, // collateral
                notional: 99670098970308907327800, // notional
                openingFeeLPAmount: 2990102969109267220, // openingFeeLPAmount
                openingFeeTreasuryAmount: 0, // openingFeeTreasuryAmount
                iporPublicationFee: 10 * Constants.D18, // iporPublicationFee
                liquidationDepositAmount: 20 * Constants.D18 // liquidationDepositAmount
            }), // money
            block.timestamp, // openTimestamp
            block.timestamp + Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // endTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
            MiltonTypes.IporSwapIndicator({
                iporIndexValue: 3 * 10 ** 16, // iporIndexValue
                ibtPrice: 1 * Constants.D18, // ibtPrice
                ibtQuantity: 99670098970308907327800, // ibtQuantity
                fixedInterestRate: 2 * 10 ** 16 // fixedInterestRate, 2%
            }) // indicator
        );
        miltonDai.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            10000 * Constants.D18, // totalAmount
            1 * 10 ** 16, // acceptableFixedInterestRate, 1%
            10 * Constants.D18 // leverage, LEVERAGE_18DEC
        );
    }

    function testShouldEmitEventWhenOpenPayFixedSwap6Decimals() public {
        // given
        UsdtMockedToken usdtMockedToken = getTokenUsdt();
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(usdtMockedToken), 0);
        IpToken ipTokenUsdt = getIpTokenUsdt(address(usdtMockedToken));
        MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(usdtMockedToken));
        (ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
        (ProxyTester miltonUsdtProxy, ItfMiltonUsdt miltonUsdt) = getItfMiltonUsdt(
            _admin,
            address(usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        (ProxyTester josephUsdtProxy, ItfJosephUsdt josephUsdt) = getItfJosephUsdt(
            _admin,
            address(usdtMockedToken),
            address(ipTokenUsdt),
            address(miltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersUsdt(users, usdtMockedToken, address(josephUsdt), address(miltonUsdt));
        prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(josephUsdt), address(miltonUsdt));
        prepareItfMiltonUsdt(miltonUsdt, address(miltonUsdtProxy), address(josephUsdt), address(stanleyUsdt));
        prepareItfJosephUsdt(josephUsdt, address(josephUsdtProxy));
        prepareIpTokenUsdt(ipTokenUsdt, address(josephUsdt));
        // when
        _miltonSpreadModel.setCalculateQuotePayFixed(4 * 10 ** 16); // 4%
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(usdtMockedToken), 3 * 10 ** 16, block.timestamp); // 3%, PERCENTAGE_3_18DEC
        vm.prank(_liquidityProvider);
        josephUsdt.itfProvideLiquidity(28000 * 10 ** 6, block.timestamp); // USD_28_000_6DEC
        vm.prank(_userTwo);
        vm.expectEmit(true, true, false, false);
        emit OpenSwap(
            1, // swapId
            _userTwo, // buyer
            address(usdtMockedToken), // asset
            MiltonTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING, // direction
            AmmTypes.OpenSwapMoney({
                totalAmount: 10000 * Constants.D18, // totalAmount
                collateral: 9967009897030890732780, // collateral
                notional: 99670098970308907327800, // notional
                openingFeeLPAmount: 2990102969109267220, // openingFeeLPAmount
                openingFeeTreasuryAmount: 0, // openingFeeTreasuryAmount
                iporPublicationFee: 10 * Constants.D18, // iporPublicationFee
                liquidationDepositAmount: 20 * Constants.D18 // liquidationDepositAmount
            }), // money
            block.timestamp, // openTimestamp
            block.timestamp + Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // endTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
            MiltonTypes.IporSwapIndicator({
                iporIndexValue: 3 * 10 ** 16, // iporIndexValue
                ibtPrice: 1 * Constants.D18, // ibtPrice
                ibtQuantity: 99670098970308907327800, // ibtQuantity
                fixedInterestRate: 4 * 10 ** 16 // fixedInterestRate, 4%
            }) // indicator
        );
        miltonUsdt.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            10000 * 10 ** 6, // totalAmount, USD_10_000_6DEC
            6 * 10 ** 16, // acceptableFixedInterestRate, 6%
            10 * 10 ** 18 // leverage, LEVERAGE_18DEC
        );
    }

    function testShouldEmitEventWhenOpenReceiveFixedSwap6Decimals() public {
        // given
        UsdtMockedToken usdtMockedToken = getTokenUsdt();
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(usdtMockedToken), 0);
        IpToken ipTokenUsdt = getIpTokenUsdt(address(usdtMockedToken));
        MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(usdtMockedToken));
        (ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
        (ProxyTester miltonUsdtProxy, ItfMiltonUsdt miltonUsdt) = getItfMiltonUsdt(
            _admin,
            address(usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        (ProxyTester josephUsdtProxy, ItfJosephUsdt josephUsdt) = getItfJosephUsdt(
            _admin,
            address(usdtMockedToken),
            address(ipTokenUsdt),
            address(miltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersUsdt(users, usdtMockedToken, address(josephUsdt), address(miltonUsdt));
        prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(josephUsdt), address(miltonUsdt));
        prepareItfMiltonUsdt(miltonUsdt, address(miltonUsdtProxy), address(josephUsdt), address(stanleyUsdt));
        prepareItfJosephUsdt(josephUsdt, address(josephUsdtProxy));
        prepareIpTokenUsdt(ipTokenUsdt, address(josephUsdt));
        // when
        _miltonSpreadModel.setCalculateQuoteReceiveFixed(2 * 10 ** 16); // 2%
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(usdtMockedToken), 3 * 10 ** 16, block.timestamp); // 3%, PERCENTAGE_3_18DEC
        vm.prank(_liquidityProvider);
        josephUsdt.itfProvideLiquidity(28000 * 10 ** 6, block.timestamp); // USD_28_000_6DEC
        vm.prank(_userTwo);
        vm.expectEmit(true, true, false, false);
        emit OpenSwap(
            1, // swapId
            _userTwo, // buyer
            address(usdtMockedToken), // asset
            MiltonTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED, // direction
            AmmTypes.OpenSwapMoney({
                totalAmount: 10000 * Constants.D18, // totalAmount
                collateral: 9967009897030890732780, // collateral
                notional: 99670098970308907327800, // notional
                openingFeeLPAmount: 2990102969109267220, // openingFeeLPAmount
                openingFeeTreasuryAmount: 0, // openingFeeTreasuryAmount
                iporPublicationFee: 10 * Constants.D18, // iporPublicationFee
                liquidationDepositAmount: 20 * Constants.D18 // liquidationDepositAmount
            }), // money
            block.timestamp, // openTimestamp
            block.timestamp + Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // endTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
            MiltonTypes.IporSwapIndicator({
                iporIndexValue: 3 * 10 ** 16, // iporIndexValue
                ibtPrice: 1 * Constants.D18, // ibtPrice
                ibtQuantity: 99670098970308907327800, // ibtQuantity
                fixedInterestRate: 2 * 10 ** 16 // fixedInterestRate, 2%
            }) // indicator
        );
        miltonUsdt.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            10000 * 10 ** 6, // totalAmount, USD_10_000_6DEC
            1 * 10 ** 16, // acceptableFixedInterestRate, 1%
            10 * 10 ** 18 // leverage, LEVERAGE_18DEC
        );
    }

    function testShouldEmitEventWhenClosePayFixedSwap18Decimals() public {
        // given
        DaiMockedToken daiMockedToken = getTokenDai();
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(daiMockedToken), 0);
        IpToken ipTokenDai = getIpTokenDai(address(daiMockedToken));
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(daiMockedToken));
        (ProxyTester miltonStorageDaiProxy, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester miltonDaiProxy, ItfMiltonDai miltonDai) = getItfMiltonDai(
            _admin,
            address(daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        (ProxyTester josephDaiProxy, ItfJosephDai josephDai) = getItfJosephDai(
            _admin,
            address(daiMockedToken),
            address(ipTokenDai),
            address(miltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersDai(users, daiMockedToken, address(josephDai), address(miltonDai));
        prepareMiltonStorage(miltonStorageDai, miltonStorageDaiProxy, address(josephDai), address(miltonDai));
        prepareItfMiltonDai(miltonDai, address(miltonDaiProxy), address(josephDai), address(stanleyDai));
        prepareItfJosephDai(josephDai, address(josephDaiProxy));
        prepareIpTokenDai(ipTokenDai, address(josephDai));
        // when
        _miltonSpreadModel.setCalculateQuotePayFixed(6 * 10 ** 16); // 6%
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(daiMockedToken), 5 * 10 ** 16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        josephDai.itfProvideLiquidity(28000 * Constants.D18, block.timestamp); // USD_28_000_18DEC
        vm.prank(_userTwo);
        miltonDai.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            10000 * Constants.D18, // totalAmount
            6 * 10 ** 16, // acceptableFixedInterestRate, 6%
            10 * Constants.D18 // leverage, LEVERAGE_18DEC
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(daiMockedToken), 160 * 10 ** 16, block.timestamp); // PERCENTAGE_160_18DEC
        vm.prank(_userTwo);
        vm.expectEmit(true, true, false, false);
        emit CloseSwap(
            1, // swapId
            address(daiMockedToken), // asset
            block.timestamp + Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // closeTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
            _userTwo, // liquidator
            18957318804358692392282, // transferredToBuyer
            0, // transferredToLiquidator
            996700989703089073278 // incomeFeeValue
        );
        miltonDai.itfCloseSwapPayFixed(
            1, // swapId
            block.timestamp + Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS // closeTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
        );
    }

    function testShouldEmitEventWhenClosePayFixedSwap6Decimals() public {
        // given
        UsdtMockedToken usdtMockedToken = getTokenUsdt();
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(usdtMockedToken), 0);
        IpToken ipTokenUsdt = getIpTokenUsdt(address(usdtMockedToken));
        MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(usdtMockedToken));
        (ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
        (ProxyTester miltonUsdtProxy, ItfMiltonUsdt miltonUsdt) = getItfMiltonUsdt(
            _admin,
            address(usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        (ProxyTester josephUsdtProxy, ItfJosephUsdt josephUsdt) = getItfJosephUsdt(
            _admin,
            address(usdtMockedToken),
            address(ipTokenUsdt),
            address(miltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersUsdt(users, usdtMockedToken, address(josephUsdt), address(miltonUsdt));
        prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(josephUsdt), address(miltonUsdt));
        prepareItfMiltonUsdt(miltonUsdt, address(miltonUsdtProxy), address(josephUsdt), address(stanleyUsdt));
        prepareItfJosephUsdt(josephUsdt, address(josephUsdtProxy));
        prepareIpTokenUsdt(ipTokenUsdt, address(josephUsdt));
        // when
        _miltonSpreadModel.setCalculateQuotePayFixed(6 * 10 ** 16); // 6%
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(usdtMockedToken), 5 * 10 ** 16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        josephUsdt.itfProvideLiquidity(28000 * 10 ** 6, block.timestamp); // USD_28_000_6DEC
        vm.prank(_userTwo);
        miltonUsdt.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            10000 * 10 ** 6, // totalAmount, USD_10_000_6DEC
            6 * 10 ** 16, // acceptableFixedInterestRate, 6%
            10 * Constants.D18 // leverage, LEVERAGE_18DEC
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(usdtMockedToken), 160 * 10 ** 16, block.timestamp); // PERCENTAGE_160_18DEC
        vm.prank(_userTwo);
        vm.expectEmit(true, true, false, false);
        emit CloseSwap(
            1, // swapId
            address(usdtMockedToken), // asset
            block.timestamp + Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // closeTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
            _userTwo, // liquidator
            18957318804000000000000, // transferredToBuyer
            0, // transferredToLiquidator
            996700989703089073278 // incomeFeeValue
        );
        miltonUsdt.itfCloseSwapPayFixed(
            1, // swapId
            block.timestamp + Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS // closeTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
        );
    }

    function testShouldEmitEventWhenClosePayFixedSwap6DecimalsNotTakerClosedSwap() public {
        // given
        UsdtMockedToken usdtMockedToken = getTokenUsdt();
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(usdtMockedToken), 0);
        IpToken ipTokenUsdt = getIpTokenUsdt(address(usdtMockedToken));
        MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(usdtMockedToken));
        (ProxyTester miltonStorageUsdtProxy, MiltonStorage miltonStorageUsdt) = getMiltonStorage(_admin);
        (ProxyTester miltonUsdtProxy, ItfMiltonUsdt miltonUsdt) = getItfMiltonUsdt(
            _admin,
            address(usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        (ProxyTester josephUsdtProxy, ItfJosephUsdt josephUsdt) = getItfJosephUsdt(
            _admin,
            address(usdtMockedToken),
            address(ipTokenUsdt),
            address(miltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        address[] memory users = getFiveUsers(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        prepareApproveForUsersUsdt(users, usdtMockedToken, address(josephUsdt), address(miltonUsdt));
        prepareMiltonStorage(miltonStorageUsdt, miltonStorageUsdtProxy, address(josephUsdt), address(miltonUsdt));
        prepareItfMiltonUsdt(miltonUsdt, address(miltonUsdtProxy), address(josephUsdt), address(stanleyUsdt));
        prepareItfJosephUsdt(josephUsdt, address(josephUsdtProxy));
        prepareIpTokenUsdt(ipTokenUsdt, address(josephUsdt));
        // when
        _miltonSpreadModel.setCalculateQuotePayFixed(6 * 10 ** 16); // 6%
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(usdtMockedToken), 5 * 10 ** 16, block.timestamp); // 5%, PERCENTAGE_5_18DEC
        vm.prank(_liquidityProvider);
        josephUsdt.itfProvideLiquidity(28000 * 10 ** 6, block.timestamp); // USD_28_000_6DEC
        vm.prank(_userTwo);
        miltonUsdt.itfOpenSwapPayFixed(
            block.timestamp, // openTimestamp
            10000 * 10 ** 6, // totalAmount, USD_10_000_6DEC
            6 * 10 ** 16, // acceptableFixedInterestRate, 6%
            10 * Constants.D18 // leverage, LEVERAGE_18DEC
        );
        vm.prank(_userOne);
        iporOracle.itfUpdateIndex(address(usdtMockedToken), 160 * 10 ** 16, block.timestamp); // PERCENTAGE_160_18DEC
        vm.prank(_userThree);
        vm.expectEmit(true, true, false, false);
        emit CloseSwap(
            1, // swapId
            address(usdtMockedToken), // asset
            block.timestamp + Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS, // closeTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
            _userThree, // liquidator
            18957318804000000000000, // transferredToBuyer
            20 * Constants.D18, // transferredToLiquidator
            996700989703089073278 // incomeFeeValue
        );
        miltonUsdt.itfCloseSwapPayFixed(
            1, // swapId
            block.timestamp + Constants.SWAP_DEFAULT_PERIOD_IN_SECONDS // closeTimestamp, 28 days, PERIOD_28_DAYS_IN_SECONDS
        );
    }

    function testShouldEmitMiltonSpreadModelChanged() public {
        // given
        DaiMockedToken daiMockedToken = getTokenDai();
        ItfIporOracle iporOracle = getIporOracleOneAsset(_admin, _userOne, address(daiMockedToken), 0);
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(daiMockedToken));
        (, MiltonStorage miltonStorageDai) = getMiltonStorage(_admin);
        (ProxyTester miltonDaiProxy, ItfMiltonDai miltonDai) = getItfMiltonDai(
            _admin,
            address(daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        vm.prank(address(miltonDaiProxy));
        address oldMiltonSpreadModel = miltonDai.getMiltonSpreadModel();
        address newMiltonSpreadModel = address(_userThree);
        // when
        vm.expectEmit(true, true, true, false);
        emit MiltonSpreadModelChanged(address(miltonDaiProxy), oldMiltonSpreadModel, newMiltonSpreadModel);
        vm.prank(address(miltonDaiProxy));
        miltonDai.setMiltonSpreadModel(newMiltonSpreadModel);
    }
}
