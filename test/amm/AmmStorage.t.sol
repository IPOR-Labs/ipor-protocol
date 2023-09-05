// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import "../../contracts/amm/AmmStorage.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";
import "../../contracts/interfaces/types/AmmStorageTypes.sol";

contract AmmStorageTest is TestCommons {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    BuilderUtils.IporProtocol internal _iporProtocol;

    function setUp() public {
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

    function testShouldTransferOwnershipSimpleCase1() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdcInstance(_cfg);

        // when
        _iporProtocol.ammStorage.transferOwnership(_userTwo);

        vm.prank(_userTwo);
        _iporProtocol.ammStorage.confirmTransferOwnership();

        // then
        vm.prank(_userOne);
        address newOwner = _iporProtocol.ammStorage.owner();
        assertEq(_userTwo, newOwner);
    }

    function testShouldNotTransferOwnershipWhenSenderIsNotCurrentOwner() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdcInstance(_cfg);

        // when
        vm.expectRevert("Ownable: caller is not the owner");

        vm.prank(_userThree);
        _iporProtocol.ammStorage.transferOwnership(_userTwo);
    }

    function testShouldNotConfirmTransferOwnershipWhenSenderNotAppointedOwner() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdcInstance(_cfg);

        // when
        _iporProtocol.ammStorage.transferOwnership(_userTwo);

        // then
        vm.expectRevert("IPOR_007");

        vm.prank(_userThree);
        _iporProtocol.ammStorage.confirmTransferOwnership();
    }

    function testShouldNotConfirmTransferOwnershipTwiceWhenSenderNotAppointedOwner() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdcInstance(_cfg);

        // when
        _iporProtocol.ammStorage.transferOwnership(_userTwo);

        vm.prank(_userTwo);
        _iporProtocol.ammStorage.confirmTransferOwnership();
        vm.expectRevert("IPOR_007");

        vm.prank(_userThree);
        _iporProtocol.ammStorage.confirmTransferOwnership();
    }

    function testShouldNotTransferOwnershipWhenSenderAlreadyLostOwnership() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdcInstance(_cfg);

        // when
        _iporProtocol.ammStorage.transferOwnership(_userTwo);

        vm.prank(_userTwo);
        _iporProtocol.ammStorage.confirmTransferOwnership();

        vm.expectRevert("Ownable: caller is not the owner");
        _iporProtocol.ammStorage.transferOwnership(_userThree);
    }

    function testShouldHaveRightsToTransferOwnershipWhenSenderStillHasRights() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdcInstance(_cfg);

        _iporProtocol.ammStorage.transferOwnership(_userTwo);

        // when
        _iporProtocol.ammStorage.transferOwnership(_userTwo);

        // then
        address actualOwner = _iporProtocol.ammStorage.owner();
        assertEq(actualOwner, _admin);
    }

    function testShouldUpdateAmmStorageWhenOpenPositionAndCallerHasRightsToUpdate() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        AmmTypes.NewSwap memory newSwap = prepareSwapPayFixedStruct18DecSimpleCase1(_userTwo);

        IAmmOpenSwapLens.AmmOpenSwapServicePoolConfiguration memory poolCfg = _iporProtocol
            .ammOpenSwapLens
            .getAmmOpenSwapServicePoolConfiguration(address(_iporProtocol.asset));

        // when
        vm.prank(address(_iporProtocol.router));
        uint256 swapId = _iporProtocol.ammStorage.updateStorageWhenOpenSwapPayFixedInternal(
            newSwap,
            poolCfg.iporPublicationFee
        );

        // then
        assertEq(swapId, 1);
    }

    function testShouldNotUpdateAmmStorageWhenOpenPositionAndCallerDoesNotHaveRightsToUpdate() public {
        // given
        _cfg.iporOracleInitialParamsTestCase = BuilderUtils.IporOracleInitialParamsTestCase.DEFAULT;
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        AmmTypes.NewSwap memory newSwap = prepareSwapPayFixedStruct18DecSimpleCase1(_userTwo);

        IAmmOpenSwapLens.AmmOpenSwapServicePoolConfiguration memory poolCfg = _iporProtocol
            .ammOpenSwapLens
            .getAmmOpenSwapServicePoolConfiguration(address(_iporProtocol.asset));

        // when
        vm.expectRevert("IPOR_008");
        vm.prank(_userThree);
        _iporProtocol.ammStorage.updateStorageWhenOpenSwapPayFixedInternal(newSwap, poolCfg.iporPublicationFee);
    }

    function testShouldNotAddLiquidityWhenAssetAmountIsZero() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdcInstance(_cfg);

        // when
        vm.expectRevert("IPOR_324");
        vm.prank(address(_iporProtocol.router));
        _iporProtocol.ammStorage.addLiquidityInternal(
            _liquidityProvider,
            TestConstants.ZERO,
            TestConstants.USD_10_000_000_18DEC
        );
    }

    function testShouldNotUpdateStorageWhenTransferredAmountToTreasuryIsGreaterThanBalance() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdcInstance(_cfg);

        // when
        vm.expectRevert("IPOR_326");
        vm.prank(address(_iporProtocol.router));
        _iporProtocol.ammStorage.updateStorageWhenTransferToTreasuryInternal(TestConstants.D18 * TestConstants.D18);
    }

    function testShouldNotUpdateStorageWhenVaultBalanceIsLowerThanDepositAmount() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdcInstance(_cfg);

        // when
        vm.expectRevert("IPOR_325");
        vm.prank(address(_iporProtocol.ammTreasury));
        _iporProtocol.ammStorage.updateStorageWhenDepositToAssetManagement(TestConstants.D18, TestConstants.ZERO);
    }

    function testShouldNotUpdateStorageWhenTransferredAmountToCharliesGreaterThanBalancer() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdcInstance(_cfg);

        // when
        vm.expectRevert("IPOR_322");
        vm.prank(address(_iporProtocol.router));
        _iporProtocol.ammStorage.updateStorageWhenTransferToCharlieTreasuryInternal(
            TestConstants.D18 * TestConstants.D18
        );
    }

    function testShouldNotUpdateStorageWhenSendZero() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdcInstance(_cfg);
        // when
        vm.expectRevert("IPOR_006");
        vm.prank(address(_iporProtocol.router));
        _iporProtocol.ammStorage.updateStorageWhenTransferToCharlieTreasuryInternal(TestConstants.ZERO);
    }

    function testShouldUpdateAmmStorageWhenClosePositionAndCallerHasRightsToUpdateDAI18Decimals() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        // when
        vm.prank(address(_iporProtocol.router));
        _iporProtocol.ammStorage.updateStorageWhenCloseSwapPayFixedInternal(
            swap,
            10 * TestConstants.D18_INT,
            0,
            0,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
    }

    function testShouldUpdateAmmStorageWhenClosePositionAndCallerHasRightsToUpdateUSDT6Decimals() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_28_000_6DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        // when
        vm.prank(address(_iporProtocol.router));
        _iporProtocol.ammStorage.updateStorageWhenCloseSwapPayFixedInternal(
            swap,
            10 * TestConstants.D18_INT,
            0,
            0,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
    }

    function testShouldNotUpdateAmmStorageWhenClosePositionAndCallerDoesNotHaveRightsToUpdate() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        // when
        vm.expectRevert("IPOR_008");
        vm.prank(address(_userOne));
        _iporProtocol.ammStorage.updateStorageWhenCloseSwapPayFixedInternal(
            swap,
            10 * TestConstants.D18_INT,
            0,
            0,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );
    }

    function testGetSwapsPayFixedShouldFailWhenPageSizeIsEqualToZero() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_50_000_6DEC);

        // when
        vm.expectRevert("IPOR_009");
        (uint256 totalCount, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            TestConstants.ZERO
        );

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(swaps.length, TestConstants.ZERO);
    }

    function testGetSwapsPayFixedShouldReturnEmptyListOfSwapsWhenZeroNumberOfSwapsAndOffsetZer0AndPageSize10() public {
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_50_000_6DEC);

        // when
        (uint256 totalCount, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            10
        );

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(swaps.length, TestConstants.ZERO);
    }

    function testGetSwapsPayFixedShouldReturnEmptyListOfSwapsWhenUserPassesNonZeroOffsetAndDoesNotHaveAnySwaps()
        public
    {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_50_000_6DEC);

        // when
        (uint256 totalCount, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            10,
            10
        );

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(swaps.length, TestConstants.ZERO);
    }

    function testGetSwapsPayFixedShouldReceiveLimitedSwapArrayWhen11NumberOfSwapsAndOffsetZeroAndPageSize10() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_50_000_6DEC);

        for (uint256 i; i < 11; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
                _userTwo,
                TestConstants.USD_100_6DEC,
                9 * TestConstants.D16,
                TestConstants.LEVERAGE_18DEC
            );
        }

        // when
        (uint256 totalCount, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            TestConstants.ZERO,
            10
        );

        // then
        assertEq(totalCount, 11);
        assertEq(swaps.length, 10);
    }

    function testGetSwapsPayFixedShouldReceiveLimitedSwapArrayWhen22NumberOfSwapsAndOffset10AndPageSize10() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_50_000_6DEC);

        for (uint256 i; i < 22; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
                _userTwo,
                TestConstants.USD_100_6DEC,
                9 * TestConstants.D16,
                TestConstants.LEVERAGE_18DEC
            );
        }

        // when
        (uint256 totalCount, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            10,
            10
        );

        // then
        assertEq(totalCount, 22);
        assertEq(swaps.length, 10);
    }

    function testGetSwapsPayFixedShouldReceiveRestOfSwapsOnlyWhen22NumberOfSwapsAndOffset20AndPageSize10() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_50_000_6DEC);

        for (uint256 i; i < 22; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
                _userTwo,
                TestConstants.USD_100_6DEC,
                9 * TestConstants.D16,
                TestConstants.LEVERAGE_18DEC
            );
        }

        // when
        (uint256 totalCount, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            20,
            10
        );

        // then
        assertEq(totalCount, 22);
        assertEq(swaps.length, 2);
    }

    function testGetSwapsPayFixedShouldReceiveEmptyListOfSwapsOnlyWhen20NumberOfSwapsAndOffset20AndPageSize10() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_50_000_6DEC);

        for (uint256 i; i < 20; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
                _userTwo,
                TestConstants.USD_100_6DEC,
                9 * TestConstants.D16,
                TestConstants.LEVERAGE_18DEC
            );
        }

        // when
        (uint256 totalCount, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsPayFixed(
            _userTwo,
            20,
            10
        );

        // then
        assertEq(totalCount, 20);
        assertEq(swaps.length, TestConstants.ZERO);
    }

    function testGetSwapsReceiveFixedShouldFailWhenPageSizeIsEqualToZero() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_50_000_6DEC);

        // when
        vm.expectRevert("IPOR_009");
        (uint256 totalCount, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            TestConstants.ZERO
        );

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(swaps.length, TestConstants.ZERO);
    }

    function testGetSwapsReceiveFixedShouldReturnEmptyListOfSwapsWhenZeroNumberOfSwapsAndOffsetZer0AndPageSize10()
        public
    {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_50_000_6DEC);

        // when
        (uint256 totalCount, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsReceiveFixed(
            _userTwo,
            TestConstants.ZERO,
            10
        );

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(swaps.length, TestConstants.ZERO);
    }

    function testGetSwapsReceiveFixedShouldReturnEmptyListOfSwapsWhenUserPassesNonZeroOffsetAndDoesNotHaveAnySwaps()
        public
    {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_50_000_6DEC);

        // when
        (uint256 totalCount, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsReceiveFixed(
            _userTwo,
            10,
            10
        );

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(swaps.length, TestConstants.ZERO);
    }

    function testGetSwapsReceiveFixedShouldReceiveLimitedSwapArrayWhen11NumberOfSwapsAndOffset10AndPageSize10() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_50_000_6DEC);

        for (uint256 i; i < 11; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
                _userTwo,
                TestConstants.USD_100_6DEC,
                1 * TestConstants.D16,
                TestConstants.LEVERAGE_18DEC
            );
        }

        // when
        (uint256 totalCount, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsReceiveFixed(
            _userTwo,
            10,
            10
        );

        // then
        assertEq(totalCount, 11);
        assertEq(swaps.length, 1);
    }

    function testGetSwapsReceiveFixedShouldReceiveLimitedSwapArrayWhen22NumberOfSwapsAndOffset10AndPageSize10() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_50_000_6DEC);

        for (uint256 i; i < 22; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
                _userTwo,
                TestConstants.USD_100_6DEC,
                1 * TestConstants.D16,
                TestConstants.LEVERAGE_18DEC
            );
        }

        // when
        (uint256 totalCount, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsReceiveFixed(
            _userTwo,
            10,
            10
        );

        // then
        assertEq(totalCount, 22);
        assertEq(swaps.length, 10);
    }

    function testGetSwapsReceiveFixedShouldReceiveRestOfSwapsOnlyWhen22NumberOfSwapsAndOffset20AndPageSize10() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_50_000_6DEC);

        for (uint256 i; i < 22; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
                _userTwo,
                TestConstants.USD_100_6DEC,
                1 * TestConstants.D16,
                TestConstants.LEVERAGE_18DEC
            );
        }

        // when
        (uint256 totalCount, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsReceiveFixed(
            _userTwo,
            20,
            10
        );

        // then
        assertEq(totalCount, 22);
        assertEq(swaps.length, 2);
    }

    function testGetSwapsReceiveFixedShouldReceiveEmptyListOfSwapsWhenOffsetIsEqualToNumberOfSwaps() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_50_000_6DEC);

        for (uint256 i; i < 20; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
                _userTwo,
                TestConstants.USD_100_6DEC,
                1 * TestConstants.D16,
                TestConstants.LEVERAGE_18DEC
            );
        }

        // when
        (uint256 totalCount, AmmTypes.Swap[] memory swaps) = _iporProtocol.ammStorage.getSwapsReceiveFixed(
            _userTwo,
            20,
            10
        );

        // then
        assertEq(totalCount, 20);
        assertEq(swaps.length, TestConstants.ZERO);
    }

    function testGetSwapIdsShouldFailWhenPageSizeIsEqualToZero() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_50_000_6DEC);

        // when
        vm.expectRevert("IPOR_009");

        (uint256 totalCount, AmmStorageTypes.IporSwapId[] memory ids) = _iporProtocol.ammStorage.getSwapIds(
            _userTwo,
            TestConstants.ZERO,
            TestConstants.ZERO
        );

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testGetSwapIdsShouldReturnEmptyListOfSwapsWhenZeroNumberOfSwapsAndOffsetZer0AndPageSize10() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_50_000_6DEC);

        // when
        (uint256 totalCount, AmmStorageTypes.IporSwapId[] memory ids) = _iporProtocol.ammStorage.getSwapIds(
            _userTwo,
            TestConstants.ZERO,
            10
        );

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testGetSwapIdsShouldReturnEmptyListOfSwapsWhenUserPassesNonZeroOffsetAndDoesNotHaveAnySwaps() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_50_000_6DEC);

        // when
        (uint256 totalCount, AmmStorageTypes.IporSwapId[] memory ids) = _iporProtocol.ammStorage.getSwapIds(
            _userTwo,
            10,
            10
        );

        // then
        assertEq(totalCount, TestConstants.ZERO);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testGetSwapIdsShouldReturnPayFixedSwapsWhenUserDoesNotHaveReceiveFixedSwapsAndOffsetZeroAndPageSize10()
        public
    {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_50_000_6DEC);

        for (uint256 i; i < 5; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
                _userTwo,
                TestConstants.USD_100_6DEC,
                9 * TestConstants.D16,
                TestConstants.LEVERAGE_18DEC
            );
        }

        // when
        (uint256 totalCount, AmmStorageTypes.IporSwapId[] memory ids) = _iporProtocol.ammStorage.getSwapIds(
            _userTwo,
            TestConstants.ZERO,
            10
        );

        // then
        assertEq(totalCount, 5);
        assertEq(ids.length, 5);
    }

    function testGetSwapIdsShouldReturnReceiveFixedSwapsWhenUserDoesNotHavePayFixedSwapsAndOffsetZeroAndPageSize10()
        public
    {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_50_000_6DEC);

        for (uint256 i; i < 5; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
                _userTwo,
                TestConstants.USD_100_6DEC,
                1 * TestConstants.D16,
                TestConstants.LEVERAGE_18DEC
            );
        }

        // when
        (uint256 totalCount, AmmStorageTypes.IporSwapId[] memory ids) = _iporProtocol.ammStorage.getSwapIds(
            _userTwo,
            TestConstants.ZERO,
            10
        );

        // then
        assertEq(totalCount, 5);
        assertEq(ids.length, 5);
    }

    function testGetSwapIdsShouldReturn6SwapsWhenUserHas3PayFixedSwapsAnd3ReceiveFixedSwapsAndOffsetZeroAndPageSize10()
        public
    {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_50_000_6DEC);

        for (uint256 i; i < 3; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
                _userTwo,
                TestConstants.USD_100_6DEC,
                9 * TestConstants.D16,
                TestConstants.LEVERAGE_18DEC
            );
        }
        for (uint256 i; i < 3; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
                _userTwo,
                TestConstants.USD_100_6DEC,
                1 * TestConstants.D16,
                TestConstants.LEVERAGE_18DEC
            );
        }

        // when
        (uint256 totalCount, AmmStorageTypes.IporSwapId[] memory ids) = _iporProtocol.ammStorage.getSwapIds(
            _userTwo,
            TestConstants.ZERO,
            10
        );

        // then
        assertEq(totalCount, 6);
        assertEq(ids.length, 6);
    }

    function testGetSwapIdsShouldReturnLimited10SwapsWhenUserHas9PayFixedSwapsAnd12ReceiveFixedSwapsAndOffsetZeroAndPageSize10()
        public
    {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_50_000_6DEC);

        for (uint256 i; i < 9; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
                _userTwo,
                TestConstants.USD_100_6DEC,
                9 * TestConstants.D16,
                TestConstants.LEVERAGE_18DEC
            );
        }
        for (uint256 i; i < 12; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
                _userTwo,
                TestConstants.USD_100_6DEC,
                1 * TestConstants.D16,
                TestConstants.LEVERAGE_18DEC
            );
        }

        // when
        (uint256 totalCount, AmmStorageTypes.IporSwapId[] memory ids) = _iporProtocol.ammStorage.getSwapIds(
            _userTwo,
            TestConstants.ZERO,
            10
        );

        // then
        assertEq(totalCount, 21);
        assertEq(ids.length, 10);
    }

    function testGetSwapIdsShouldReturnEmptyArrayWhenUserHasMoreSwapsThanPageSizeAndOffset80AndPageSize10() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_50_000_6DEC);

        for (uint256 i; i < 9; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
                _userTwo,
                TestConstants.USD_100_6DEC,
                9 * TestConstants.D16,
                TestConstants.LEVERAGE_18DEC
            );
        }
        for (uint256 i; i < 12; ++i) {
            vm.prank(_userTwo);
            _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
                _userTwo,
                TestConstants.USD_100_6DEC,
                1 * TestConstants.D16,
                TestConstants.LEVERAGE_18DEC
            );
        }

        // when
        (uint256 totalCount, AmmStorageTypes.IporSwapId[] memory ids) = _iporProtocol.ammStorage.getSwapIds(
            _userTwo,
            80,
            10
        );

        // then
        assertEq(totalCount, 21);
        assertEq(ids.length, TestConstants.ZERO);
    }

    function testShouldPauseSCWhenSenderIsPauseGuardian() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        _iporProtocol.ammStorage.addPauseGuardian(_admin);
        bool pausedBefore = _iporProtocol.ammStorage.paused();

        // when
        _iporProtocol.ammStorage.pause();

        // then
        bool pausedAfter = _iporProtocol.ammStorage.paused();

        assertEq(pausedBefore, false);
        assertEq(pausedAfter, true);
    }

    function testShouldNotPauseSCSpecificMethods() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        _iporProtocol.ammStorage.addPauseGuardian(_admin);
        _iporProtocol.ammStorage.pause();

        bool pausedBefore = _iporProtocol.ammStorage.paused();

        // when
        vm.startPrank(_getUserAddress(1));
        _iporProtocol.ammStorage.getVersion();
        _iporProtocol.ammStorage.isPauseGuardian(_getUserAddress(1));
        _iporProtocol.ammStorage.getLastSwapId();
        _iporProtocol.ammStorage.getLastOpenedSwap(IporTypes.SwapTenor.DAYS_28, 0);
        _iporProtocol.ammStorage.getBalance();
        _iporProtocol.ammStorage.getBalancesForOpenSwap();
        _iporProtocol.ammStorage.getExtendedBalance();
        _iporProtocol.ammStorage.getSoapIndicators();
        _iporProtocol.ammStorage.getSwap(AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING, 1);
        _iporProtocol.ammStorage.getSwapsPayFixed(_admin, 0, 10);
        _iporProtocol.ammStorage.getSwapsReceiveFixed(_admin, 0, 10);
        _iporProtocol.ammStorage.getSwapIds(_admin, 0, 10);
        vm.stopPrank();

        // admin
        _iporProtocol.ammStorage.addPauseGuardian(_getUserAddress(1));
        _iporProtocol.ammStorage.removePauseGuardian(_getUserAddress(1));

        // then
        bool pausedAfter = _iporProtocol.ammStorage.paused();
        assertEq(pausedBefore, true);
        assertEq(pausedAfter, true);
    }

    function testShouldNotPauseSmartContractWhenSenderIsNotAnPauseGuardian() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        bool pausedBefore = _iporProtocol.ammStorage.paused();

        // when
        vm.prank(_getUserAddress(1));
        vm.expectRevert(abi.encodePacked("IPOR_011"));
        _iporProtocol.ammStorage.pause();

        // then
        bool pausedAfter = _iporProtocol.ammStorage.paused();

        assertEq(pausedBefore, false);
        assertEq(pausedAfter, false);
    }

    function testShouldUnpauseSmartContractWhenSenderIsAnAdmin() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        _iporProtocol.ammStorage.addPauseGuardian(_admin);
        _iporProtocol.ammStorage.pause();
        _iporProtocol.ammStorage.removePauseGuardian(_admin);

        bool pausedBefore = _iporProtocol.ammStorage.paused();

        // when
        _iporProtocol.ammStorage.unpause();

        // then
        bool pausedAfter = _iporProtocol.ammStorage.paused();

        assertEq(pausedBefore, true);
        assertEq(pausedAfter, false);
    }

    function testShouldNotUnpauseSmartContractWhenSenderIsNotAnAdmin() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);
        _iporProtocol.ammStorage.addPauseGuardian(_admin);
        _iporProtocol.ammStorage.pause();
        _iporProtocol.ammStorage.removePauseGuardian(_admin);

        bool pausedBefore = _iporProtocol.ammStorage.paused();

        // when
        vm.prank(_getUserAddress(1));
        vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
        _iporProtocol.ammStorage.unpause();

        // then
        bool pausedAfter = _iporProtocol.ammStorage.paused();

        assertEq(pausedBefore, true);
        assertEq(pausedAfter, true);
    }

    function testShouldUpdateUnwindAmountWhenClosePayFixedDai() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        AmmStorageTypes.ExtendedBalancesMemory memory balanceAfterOpenSwap = _iporProtocol
            .ammStorage
            .getExtendedBalance();

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        uint256 swapUnwindFeeLPAmount = 100e18;
        uint256 swapUnwindFeeTreasuryAmount = 30e18;
        int256 pnlValue = 10 * TestConstants.D18_INT;

        // when
        vm.prank(address(_iporProtocol.router));
        _iporProtocol.ammStorage.updateStorageWhenCloseSwapPayFixedInternal(
            swap,
            pnlValue,
            swapUnwindFeeLPAmount,
            swapUnwindFeeTreasuryAmount,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );

        AmmStorageTypes.ExtendedBalancesMemory memory balanceAfterCloseSwap = _iporProtocol
            .ammStorage
            .getExtendedBalance();

        //then
        assertEq(
            balanceAfterCloseSwap.liquidityPool,
            balanceAfterOpenSwap.liquidityPool + swapUnwindFeeLPAmount - uint256(pnlValue)
        );
        assertEq(balanceAfterCloseSwap.treasury, balanceAfterOpenSwap.treasury + swapUnwindFeeTreasuryAmount);
    }

    function testShouldUpdateUnwindAmountWhenClosePayFixedUsdt() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_28_000_6DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        AmmStorageTypes.ExtendedBalancesMemory memory balanceAfterOpenSwap = _iporProtocol
            .ammStorage
            .getExtendedBalance();

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING,
            1
        );

        uint256 swapUnwindFeeLPAmount = 100e18;
        uint256 swapUnwindFeeTreasuryAmount = 30e18;
        int256 pnlValue = 10 * TestConstants.D18_INT;

        // when
        vm.prank(address(_iporProtocol.router));
        _iporProtocol.ammStorage.updateStorageWhenCloseSwapPayFixedInternal(
            swap,
            pnlValue,
            swapUnwindFeeLPAmount,
            swapUnwindFeeTreasuryAmount,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );

        AmmStorageTypes.ExtendedBalancesMemory memory balanceAfterCloseSwap = _iporProtocol
            .ammStorage
            .getExtendedBalance();

        //then
        assertEq(
            balanceAfterCloseSwap.liquidityPool,
            balanceAfterOpenSwap.liquidityPool + swapUnwindFeeLPAmount - uint256(pnlValue)
        );
        assertEq(balanceAfterCloseSwap.treasury, balanceAfterOpenSwap.treasury + swapUnwindFeeTreasuryAmount);
    }

    function testShouldUpdateUnwindAmountWhenCloseReceiveFixedDai() public {
        //given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_28_000_18DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            0,
            TestConstants.LEVERAGE_18DEC
        );

        AmmStorageTypes.ExtendedBalancesMemory memory balanceAfterOpenSwap = _iporProtocol
            .ammStorage
            .getExtendedBalance();

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            1
        );

        uint256 swapUnwindFeeLPAmount = 100e18;
        uint256 swapUnwindFeeTreasuryAmount = 30e18;
        int256 pnlValue = 10 * TestConstants.D18_INT;

        // when
        vm.prank(address(_iporProtocol.router));
        _iporProtocol.ammStorage.updateStorageWhenCloseSwapReceiveFixedInternal(
            swap,
            pnlValue,
            swapUnwindFeeLPAmount,
            swapUnwindFeeTreasuryAmount,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );

        AmmStorageTypes.ExtendedBalancesMemory memory balanceAfterCloseSwap = _iporProtocol
            .ammStorage
            .getExtendedBalance();

        //then
        assertEq(
            balanceAfterCloseSwap.liquidityPool,
            balanceAfterOpenSwap.liquidityPool + swapUnwindFeeLPAmount - uint256(pnlValue)
        );
        assertEq(balanceAfterCloseSwap.treasury, balanceAfterOpenSwap.treasury + swapUnwindFeeTreasuryAmount);
    }

    function testShouldUpdateUnwindAmountWhenCloseReceiveFixedUsdt() public {
        //given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_28_000_6DEC);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC
        );

        AmmStorageTypes.ExtendedBalancesMemory memory balanceAfterOpenSwap = _iporProtocol
            .ammStorage
            .getExtendedBalance();

        AmmTypes.Swap memory swap = _iporProtocol.ammStorage.getSwap(
            AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED,
            1
        );

        uint256 swapUnwindFeeLPAmount = 100e18;
        uint256 swapUnwindFeeTreasuryAmount = 30e18;
        int256 pnlValue = 10 * TestConstants.D18_INT;

        // when
        vm.prank(address(_iporProtocol.router));
        _iporProtocol.ammStorage.updateStorageWhenCloseSwapReceiveFixedInternal(
            swap,
            pnlValue,
            swapUnwindFeeLPAmount,
            swapUnwindFeeTreasuryAmount,
            block.timestamp + TestConstants.PERIOD_25_DAYS_IN_SECONDS
        );

        AmmStorageTypes.ExtendedBalancesMemory memory balanceAfterCloseSwap = _iporProtocol
            .ammStorage
            .getExtendedBalance();

        //then
        assertEq(
            balanceAfterCloseSwap.liquidityPool,
            balanceAfterOpenSwap.liquidityPool + swapUnwindFeeLPAmount - uint256(pnlValue)
        );
        assertEq(balanceAfterCloseSwap.treasury, balanceAfterOpenSwap.treasury + swapUnwindFeeTreasuryAmount);
    }
}
