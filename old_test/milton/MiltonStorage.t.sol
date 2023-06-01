// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "contracts/amm/AmmStorage.sol";
import "contracts/mocks/spread/MockSpreadModel.sol";
import "contracts/interfaces/types/AmmTypes.sol";
import "contracts/interfaces/types/AmmStorageTypes.sol";
import "contracts/interfaces/types/IporTypes.sol";

contract AmmStorageTest is TestCommons, DataUtils, SwapUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    BuilderUtils.IporProtocol internal _iporProtocol;

    AmmStorageBuilder _ammStorageBuilder;

    address internal _ammStorageAddress;

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _ammStorageAddress = _getUserAddress(5);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);

        _cfg.approvalsForUsers = _users;
        _cfg.iporOracleUpdater = _userOne;
        _cfg.iporRiskManagementOracleUpdater = _userOne;

        _cfg.spreadImplementation = address(
            new MockSpreadModel(
                TestConstants.PERCENTAGE_6_18DEC,
                TestConstants.PERCENTAGE_4_18DEC,
                TestConstants.ZERO_INT,
                TestConstants.ZERO_INT
            )
        );

        _ammStorageBuilder = new AmmStorageBuilder(
            address(this)
        );
    }

    function testShouldTransferOwnershipSimpleCase1() public {
        // given
        AmmStorage ammStorage = _ammStorageBuilder.build();

        // when
        ammStorage.transferOwnership(_userTwo);

        vm.prank(_userTwo);
        ammStorage.confirmTransferOwnership();

        // then
        vm.prank(_userOne);
        address newOwner = ammStorage.owner();
        assertEq(_userTwo, newOwner);
    }

    function testShouldNotTransferOwnershipWhenSenderIsNotCurrentOwner() public {
        // given
        AmmStorage ammStorage = _ammStorageBuilder.build();

        // when
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(_userThree);
        ammStorage.transferOwnership(_userTwo);
    }

    function testShouldNotConfirmTransferOwnershipWhenSenderNotAppointedOwner() public {
        // given
        AmmStorage ammStorage = _ammStorageBuilder.build();

        // when
        ammStorage.transferOwnership(_userTwo);

        // then
        vm.expectRevert("IPOR_007");

        vm.prank(_userThree);
        ammStorage.confirmTransferOwnership();
    }

    function testShouldNotConfirmTransferOwnershipTwiceWhenSenderNotAppointedOwner() public {
        // given
        AmmStorage ammStorage = _ammStorageBuilder.build();

        // when
        ammStorage.transferOwnership(_userTwo);

        vm.prank(_userTwo);
        ammStorage.confirmTransferOwnership();
        vm.expectRevert("IPOR_007");

        vm.prank(_userThree);
        ammStorage.confirmTransferOwnership();
    }

    function testShouldNotTransferOwnershipWhenSenderAlreadyLostOwnership() public {
        // given
        AmmStorage ammStorage = _ammStorageBuilder.build();

        // when
        ammStorage.transferOwnership(_userTwo);

        vm.prank(_userTwo);
        ammStorage.confirmTransferOwnership();

        vm.expectRevert("Ownable: caller is not the owner");
        ammStorage.transferOwnership(_userThree);
    }

    function testShouldHaveRightsToTransferOwnershipWhenSenderStillHasRights() public {
        // given
        AmmStorage ammStorage = _ammStorageBuilder.build();
        ammStorage.transferOwnership(_userTwo);

        // when
        ammStorage.transferOwnership(_userTwo);

        // then
        address actualOwner = ammStorage.owner();
        assertEq(actualOwner, _admin);
    }

    function testShouldUpdateAmmStorageWhenOpenPositionAndCallerHasRightsToUpdate() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
       _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.ammStorage.setAmmTreasury(_ammStorageAddress);

        AmmTypes.NewSwap memory newSwap = prepareSwapPayFixedStruct18DecSimpleCase1(_userTwo);
        uint256 iporPublicationFee = _iporProtocol.ammTreasury.getIporPublicationFee();

        // when
        vm.prank(_ammStorageAddress);
        uint256 swapId = _iporProtocol.ammStorage.updateStorageWhenOpenSwapPayFixed(
            newSwap,
            iporPublicationFee
        );

        // then
        assertEq(swapId, 1);
    }

    function testShouldNotUpdateAmmStorageWhenOpenPositionAndCallerDoesNotHaveRightsToUpdate()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
       _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        _iporProtocol.ammStorage.setAmmTreasury(_ammStorageAddress);

        AmmTypes.NewSwap memory newSwap = prepareSwapPayFixedStruct18DecSimpleCase1(_userTwo);
        uint256 iporPublicationFee = _iporProtocol.ammTreasury.getIporPublicationFee();

        // when
        vm.expectRevert("IPOR_008");
        vm.prank(_userThree);
        _iporProtocol.ammStorage.updateStorageWhenOpenSwapPayFixed(newSwap, iporPublicationFee);
    }

    function testShouldNotAddLiquidityWhenAssetAmountIsZero() public {
        //given
        AmmStorage ammStorage = _ammStorageBuilder.build();
        ammStorage.setJoseph(_liquidityProvider);

        // when
        vm.expectRevert("IPOR_328");
        vm.prank(_liquidityProvider);
        ammStorage.addLiquidity(
            _liquidityProvider,
            TestConstants.ZERO,
            TestConstants.USD_10_000_000_18DEC,
            TestConstants.USD_10_000_000_18DEC
        );
    }

    function testShouldNotUpdateStorageWhenTransferredAmountToTreasuryIsGreaterThanBalance()
        public
    {
        //given
        AmmStorage ammStorage = _ammStorageBuilder.build();
        ammStorage.setJoseph(_liquidityProvider);

        // when
        vm.expectRevert("IPOR_330");
        vm.prank(_liquidityProvider);
        ammStorage.updateStorageWhenTransferToTreasury(TestConstants.D18 * TestConstants.D18);
    }

    function testShouldNotUpdateStorageWhenVaultBalanceIsLowerThanDepositAmount() public {
        //given
        AmmStorage ammStorage = _ammStorageBuilder.build();
        ammStorage.setAmmTreasury(_ammStorageAddress);

        // when
        vm.expectRevert("IPOR_329");
        vm.prank(_ammStorageAddress);
        ammStorage.updateStorageWhenDepositToAssetManagement(TestConstants.D18, TestConstants.ZERO);
    }

    function testShouldNotUpdateStorageWhenTransferredAmountToCharliesGreaterThanBalacer() public {
        //given
        AmmStorage ammStorage = _ammStorageBuilder.build();
        ammStorage.setJoseph(_liquidityProvider);

        // when
        vm.expectRevert("IPOR_326");
        vm.prank(_liquidityProvider);
        ammStorage.updateStorageWhenTransferToCharlieTreasury(
            TestConstants.D18 * TestConstants.D18
        );
    }

    function testShouldNotUpdateStorageWhenSendZero() public {
        //given
        AmmStorage ammStorage = _ammStorageBuilder.build();
        ammStorage.setJoseph(_liquidityProvider);

        // when
        vm.expectRevert("IPOR_006");
        vm.prank(_liquidityProvider);
        ammStorage.updateStorageWhenTransferToCharlieTreasury(TestConstants.ZERO);
    }

    function testShouldUpdateAmmStorageWhenClosePositionAndCallerHasRightsToUpdateDAI18Decimals()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
       _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        _iporProtocol.ammStorage.setAmmTreasury(_ammStorageAddress);

        vm.prank(address(_iporProtocol.ammTreasury));
        IporTypes.IporSwapMemory memory derivativeItem = _iporProtocol
            .ammStorage
            .getSwapPayFixed(1);

        // when
        vm.prank(_ammStorageAddress);
        _iporProtocol.ammStorage.updateStorageWhenCloseSwapPayFixed(
            derivativeItem,
            10 * TestConstants.D18_INT,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
    }

    function testShouldUpdateAmmStorageWhenClosePositionAndCallerHasRightsToUpdateUSDT6Decimals()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_6DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        _iporProtocol.ammStorage.setAmmTreasury(_ammStorageAddress);

        vm.prank(address(_iporProtocol.ammTreasury));
        IporTypes.IporSwapMemory memory derivativeItem = _iporProtocol
            .ammStorage
            .getSwapPayFixed(1);

        // when
        vm.prank(_ammStorageAddress);
        _iporProtocol.ammStorage.updateStorageWhenCloseSwapPayFixed(
            derivativeItem,
            10 * TestConstants.D18_INT,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
    }

    function testShouldNotUpdateAmmStorageWhenClosePositionAndCallerDoesNotHaveRightsToUpdate()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
       _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_28_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammTreasury.openSwapPayFixed(
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        _iporProtocol.ammStorage.setAmmTreasury(_ammStorageAddress);
        IporTypes.IporSwapMemory memory derivativeItem = _iporProtocol
            .ammStorage
            .getSwapPayFixed(1);

        // when
        vm.expectRevert("IPOR_008");
        vm.prank(_userThree);
        _iporProtocol.ammStorage.updateStorageWhenCloseSwapPayFixed(
            derivativeItem,
            10 * TestConstants.D18_INT,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
    }

    function testGetSwapsPayFixedShouldFailWhenPageSizeIsEqualToZero() public {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        // when
        vm.expectRevert("IPOR_009");
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol
            .ammStorage
            .getSwapsPayFixed(_userTwo, TestConstants.ZERO, TestConstants.ZERO);

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(swaps.length, TestConstants.ZERO);
    }

    function testGetSwapsPayFixedShouldReturnEmptyListOfSwapsWhenZeroNumberOfSwapsAndOffsetZer0AndPageSize10()
        public
    {
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        // when
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol
            .ammStorage
            .getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(swaps.length, TestConstants.ZERO);
    }

    function testGetSwapsPayFixedShouldReturnEmptyListOfSwapsWhenUserPassesNonZeroOffsetAndDoesNotHaveAnySwaps()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        // when
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol
            .ammStorage
            .getSwapsPayFixed(_userTwo, 10, 10);

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(swaps.length, TestConstants.ZERO);
    }

    function testGetSwapsPayFixedShouldReceiveLimitedSwapArrayWhen11NumberOfSwapsAndOffsetZeroAndPageSize10()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        iterateOpenSwapsPayFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            11,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol
            .ammStorage
            .getSwapsPayFixed(_userTwo, TestConstants.ZERO, 10);

        // then
        assertEq(totalCount, 11);
        assertEq(swaps.length, 10);
    }

    function testGetSwapsPayFixedShouldReceiveLimitedSwapArrayWhen22NumberOfSwapsAndOffset10AndPageSize10()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        iterateOpenSwapsPayFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            22,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol
            .ammStorage
            .getSwapsPayFixed(_userTwo, 10, 10);

        // then
        assertEq(totalCount, 22);
        assertEq(swaps.length, 10);
    }

    function testGetSwapsPayFixedShouldReceiveRestOfSwapsOnlyWhen22NumberOfSwapsAndOffset20AndPageSize10()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        iterateOpenSwapsPayFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            22,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol
            .ammStorage
            .getSwapsPayFixed(_userTwo, 20, 10);

        // then
        assertEq(totalCount, 22);
        assertEq(swaps.length, 2);
    }

    function testGetSwapsPayFixedShouldReceiveEmptyListOfSwapsOnlyWhen20NumberOfSwapsAndOffset20AndPageSize10()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        iterateOpenSwapsPayFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            20,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol
            .ammStorage
            .getSwapsPayFixed(_userTwo, 20, 10);

        // then
        assertEq(totalCount, 20);
        assertEq(swaps.length, TestConstants.ZERO);
    }

    function testGetSwapsReceiveFixedShouldFailWhenPageSizeIsEqualToZero() public {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        iterateOpenSwapsReceiveFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            0,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        vm.expectRevert("IPOR_009");
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol
            .ammStorage
            .getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, TestConstants.ZERO);

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(swaps.length, TestConstants.ZERO);
    }

    function testGetSwapsReceiveFixedShouldReturnEmptyListOfSwapsWhenZeroNumberOfSwapsAndOffsetZer0AndPageSize10()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        iterateOpenSwapsReceiveFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            0,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol
            .ammStorage
            .getSwapsReceiveFixed(_userTwo, TestConstants.ZERO, 10);

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(swaps.length, TestConstants.ZERO);
    }

    function testGetSwapsReceiveFixedShouldReturnEmptyListOfSwapsWhenUserPassesNonZeroOffsetAndDoesNotHaveAnySwaps()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        // when
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol
            .ammStorage
            .getSwapsReceiveFixed(_userTwo, 10, 10);

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(swaps.length, TestConstants.ZERO);
    }

    function testGetSwapsReceiveFixedShouldReceiveLimitedSwapArrayWhen11NumberOfSwapsAndOffset10AndPageSize10()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        iterateOpenSwapsReceiveFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            11,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol
            .ammStorage
            .getSwapsReceiveFixed(_userTwo, 10, 10);

        // then
        assertEq(totalCount, 11);
        assertEq(swaps.length, 1);
    }

    function testGetSwapsReceiveFixedShouldReceiveLimitedSwapArrayWhen22NumberOfSwapsAndOffset10AndPageSize10()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        iterateOpenSwapsReceiveFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            22,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol
            .ammStorage
            .getSwapsReceiveFixed(_userTwo, 10, 10);

        // then
        assertEq(totalCount, 22);
        assertEq(swaps.length, 10);
    }

    function testGetSwapsReceiveFixedShouldReceiveRestOfSwapsOnlyWhen22NumberOfSwapsAndOffset20AndPageSize10()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        iterateOpenSwapsReceiveFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            22,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol
            .ammStorage
            .getSwapsReceiveFixed(_userTwo, 20, 10);

        // then
        assertEq(totalCount, 22);
        assertEq(swaps.length, 2);
    }

    function testGetSwapsReceiveFixedShouldReceiveEmptyListOfSwapsWhenOffsetIsEqualToNumberOfSwaps()
        public
    {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        iterateOpenSwapsReceiveFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            20,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        (uint256 totalCount, IporTypes.IporSwapMemory[] memory swaps) = _iporProtocol
            .ammStorage
            .getSwapsReceiveFixed(_userTwo, 20, 10);

        // then
        assertEq(totalCount, 20);
        assertEq(swaps.length, TestConstants.ZERO);
    }

    function testGetSwapIdsPayFixedShouldFailWhenPageSizeIsEqualToZero() public {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        // when
        vm.expectRevert("IPOR_009");
        (uint256 totalCount, uint256[] memory ids) = _iporProtocol.ammStorage.getSwapPayFixedIds(
            _userTwo,
            0,
            0
        );

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testGetSwapIdsPayFixedShouldReturnEmptyListOfSwapsWhenZeroNumberOfSwapsAndOffsetZer0AndPageSize10()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        // when
        (uint256 totalCount, uint256[] memory ids) = _iporProtocol.ammStorage.getSwapPayFixedIds(
            _userTwo,
            TestConstants.ZERO,
            10
        );

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testGetSwapIdsPayFixedShouldReturnEmptyListOfSwapsWhenUserPassesNonZeroOffsetAndDoesNotHaveAnySwaps()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        // when
        (uint256 totalCount, uint256[] memory ids) = _iporProtocol.ammStorage.getSwapPayFixedIds(
            _userTwo,
            10,
            10
        );

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testGetSwapIdsPayFixedShouldReceiveLimitedSwapArrayWhen11NumberOfSwapsAndOffsetZeroAndPageSize10()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        iterateOpenSwapsPayFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            11,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        (uint256 totalCount, uint256[] memory ids) = _iporProtocol.ammStorage.getSwapPayFixedIds(
            _userTwo,
            TestConstants.ZERO,
            10
        );

        // then
        assertEq(totalCount, 11);
        assertEq(ids.length, 10);
    }

    function testGetSwapIdsPayFixedShouldReceiveLimitedSwapArrayWhen22NumberOfSwapsAndOffset10AndPageSize10()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        iterateOpenSwapsPayFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            22,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        (uint256 totalCount, uint256[] memory ids) = _iporProtocol.ammStorage.getSwapPayFixedIds(
            _userTwo,
            10,
            10
        );

        // then
        assertEq(totalCount, 22);
        assertEq(ids.length, 10);
    }

    function testGetSwapIdsPayFixedShouldReceiveRestOfSwapsOnlyWhen22NumberOfSwapsAndOffset20AndPageSize10()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        iterateOpenSwapsPayFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            22,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        (uint256 totalCount, uint256[] memory ids) = _iporProtocol.ammStorage.getSwapPayFixedIds(
            _userTwo,
            20,
            10
        );

        // then
        assertEq(totalCount, 22);
        assertEq(ids.length, 2);
    }

    function testGetSwapIdsPayFixedShouldReceiveEmptyListOfSwapsOnlyWhen20NumberOfSwapsAndOffset20AndPageSize10()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        iterateOpenSwapsPayFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            20,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        (uint256 totalCount, uint256[] memory ids) = _iporProtocol.ammStorage.getSwapPayFixedIds(
            _userTwo,
            20,
            10
        );

        // then
        assertEq(totalCount, 20);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testGetSwapIdsReceiveFixedShouldFailWhenPageSizeIsEqualToZero() public {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        // when
        vm.expectRevert("IPOR_009");
        (uint256 totalCount, uint256[] memory ids) = _iporProtocol
            .ammStorage
            .getSwapReceiveFixedIds(_userTwo, TestConstants.ZERO, TestConstants.ZERO);

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testGetSwapIdsReceiveFixedShouldReturnEmptyListOfSwapsWhenZeroNumberOfSwapsAndOffsetZer0AndPageSize10()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        // when
        (uint256 totalCount, uint256[] memory ids) = _iporProtocol
            .ammStorage
            .getSwapReceiveFixedIds(_userTwo, TestConstants.ZERO, 10);

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testGetSwapIdsReceiveFixedShouldReturnEmptyListOfSwapsWhenUserPassesNonZeroOffsetAndDoesNotHaveAnySwaps()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        // when
        (uint256 totalCount, uint256[] memory ids) = _iporProtocol
            .ammStorage
            .getSwapReceiveFixedIds(_userTwo, 10, 10);

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testGetSwapIdsReceiveFixedShouldReceiveLimitedSwapArrayWhen11NumberOfSwapsAndOffset10AndPageSize10()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        iterateOpenSwapsReceiveFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            11,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        (uint256 totalCount, uint256[] memory ids) = _iporProtocol
            .ammStorage
            .getSwapReceiveFixedIds(_userTwo, 10, 10);

        // then
        assertEq(totalCount, 11);
        assertEq(ids.length, 1);
    }

    function testGetSwapIdsReceiveFixedShouldReceiveLimitedSwapArrayWhen22NumberOfSwapsAndOffset10AndPageSize10()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        iterateOpenSwapsReceiveFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            22,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        (uint256 totalCount, uint256[] memory ids) = _iporProtocol
            .ammStorage
            .getSwapReceiveFixedIds(_userTwo, 10, 10);

        // then
        assertEq(totalCount, 22);
        assertEq(ids.length, 10);
    }

    function testGetSwapIdsReceiveFixedShouldReceiveRestOfSwapsOnlyWhen22NumberOfSwapsAndOffset20AndPageSize10()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        iterateOpenSwapsReceiveFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            22,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        (uint256 totalCount, uint256[] memory ids) = _iporProtocol
            .ammStorage
            .getSwapReceiveFixedIds(_userTwo, 20, 10);

        // then
        assertEq(totalCount, 22);
        assertEq(ids.length, 2);
    }

    function testGetSwapIdsShouldFailWhenPageSizeIsEqualToZero() public {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        // when
        vm.expectRevert("IPOR_009");

        (uint256 totalCount, AmmStorageTypes.IporSwapId[] memory ids) = _iporProtocol
            .ammStorage
            .getSwapIds(_userTwo, TestConstants.ZERO, TestConstants.ZERO);

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testGetSwapIdsShouldReturnEmptyListOfSwapsWhenZeroNumberOfSwapsAndOffsetZer0AndPageSize10()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        // when
        (uint256 totalCount, AmmStorageTypes.IporSwapId[] memory ids) = _iporProtocol
            .ammStorage
            .getSwapIds(_userTwo, TestConstants.ZERO, 10);

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testGetSwapIdsShouldReturnEmptyListOfSwapsWhenUserPassesNonZeroOffsetAndDoesNotHaveAnySwaps()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        // when
        (uint256 totalCount, AmmStorageTypes.IporSwapId[] memory ids) = _iporProtocol
            .ammStorage
            .getSwapIds(_userTwo, 10, 10);

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testGetSwapIdsShouldReturnPayFixedSwapsWhenUserDoesNotHaveReceiveFixedSwapsAndOffsetZeroAndPageSize10()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        iterateOpenSwapsPayFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            5,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        (uint256 totalCount, AmmStorageTypes.IporSwapId[] memory ids) = _iporProtocol
            .ammStorage
            .getSwapIds(_userTwo, TestConstants.ZERO, 10);

        // then
        assertEq(totalCount, 5);
        assertEq(ids.length, 5);
    }

    function testGetSwapIdsShouldReturnReceiveFixedSwapsWhenUserDoesNotHavePayFixedSwapsAndOffsetZeroAndPageSize10()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        iterateOpenSwapsReceiveFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            5,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        (uint256 totalCount, AmmStorageTypes.IporSwapId[] memory ids) = _iporProtocol
            .ammStorage
            .getSwapIds(_userTwo, TestConstants.ZERO, 10);

        // then
        assertEq(totalCount, 5);
        assertEq(ids.length, 5);
    }

    function testGetSwapIdsShouldReturn6SwapsWhenUserHas3PayFixedSwapsAnd3ReceiveFixedSwapsAndOffsetZeroAndPageSize10()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        iterateOpenSwapsPayFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            3,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsReceiveFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            3,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        (uint256 totalCount, AmmStorageTypes.IporSwapId[] memory ids) = _iporProtocol
            .ammStorage
            .getSwapIds(_userTwo, TestConstants.ZERO, 10);

        // then
        assertEq(totalCount, 6);
        assertEq(ids.length, 6);
    }

    function testGetSwapIdsShouldReturnLimited10SwapsWhenUserHas9PayFixedSwapsAnd12ReceiveFixedSwapsAndOffsetZeroAndPageSize10()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        iterateOpenSwapsPayFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            9,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsReceiveFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            12,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        (uint256 totalCount, AmmStorageTypes.IporSwapId[] memory ids) = _iporProtocol
            .ammStorage
            .getSwapIds(_userTwo, TestConstants.ZERO, 10);

        // then
        assertEq(totalCount, 21);
        assertEq(ids.length, 10);
    }

    function testGetSwapIdsShouldReturnEmptyArrayWhenUserHasMoreSwapsThanPageSizeAndOffset80AndPageSize10()
        public
    {
        //given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.CASE5;
        _cfg.ammTreasuryTestCase = BuilderUtils.AmmTreasuryTestCase.CASE0;
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_5_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.provideLiquidity(TestConstants.USD_50_000_6DEC);

        iterateOpenSwapsPayFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            9,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );
        iterateOpenSwapsReceiveFixed(
            _userTwo,
            _iporProtocol.ammTreasury,
            12,
            TestConstants.USD_100_6DEC,
            TestConstants.LEVERAGE_18DEC
        );

        // when
        (uint256 totalCount, AmmStorageTypes.IporSwapId[] memory ids) = _iporProtocol
            .ammStorage
            .getSwapIds(_userTwo, 80, 10);

        // then
        assertEq(totalCount, 21);
        assertEq(ids.length, TestConstants.ZERO);
    }
}
