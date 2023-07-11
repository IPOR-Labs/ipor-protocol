// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../TestCommons.sol";
import "../utils/TestConstants.sol";

contract AmmSoapAndCloseSwapTest is TestCommons {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    IporProtocolFactory.AmmConfig private _ammCfg;
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

        _ammCfg.iporOracleUpdater = _userOne;
        _ammCfg.iporRiskManagementOracleUpdater = _userOne;
    }


    function testShouldOpenSwapWhenFixedInterestRateEqualOneIsHigherThanZero() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_liquidityProvider);

        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, 2 * TestConstants.USD_28_000_6DEC);

        /// @dev for this particular case fixedInterestRate is higher than 0 (is equal 1)
        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), 1111516737937797);

        vm.prank(_userTwo);
        uint256 swap1 = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC
        );
        uint256[] memory pfAwapIds = new uint256[](0);
        uint256[] memory swapIds = new uint256[](1);
        swapIds[0] = swap1;
        vm.prank(_userTwo);
        _iporProtocol.ammCloseSwapService.closeSwapsUsdt(_userOne, pfAwapIds, swapIds);
    }

    function testShouldNotCloseBecauseAverageInterestRateIsEqualZero() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, 2 * TestConstants.USD_28_000_6DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_userTwo);
        uint256 swap1 = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), 0);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC
        );
        vm.warp(30 days);

        uint256[] memory pfAwapIds = new uint256[](0);
        uint256[] memory swapIds = new uint256[](1);
        swapIds[0] = swap1;
        vm.prank(_userTwo);
        vm.expectRevert("IPOR_341");
        _iporProtocol.ammCloseSwapService.closeSwapsUsdt(_userOne, pfAwapIds, swapIds);
    }

    function testShouldNotCloseSwapIncorrectHypotheticalInterestCase1() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, 2 * TestConstants.USD_28_000_6DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_userTwo);
        uint256 swap1 = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), 1424808299999999);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC
        );
        vm.warp(30 days);

        uint256[] memory pfAwapIds = new uint256[](0);
        uint256[] memory swapIds = new uint256[](1);
        swapIds[0] = swap1;
        vm.prank(_userTwo);
        vm.expectRevert("IPOR_343");
        _iporProtocol.ammCloseSwapService.closeSwapsUsdt(_userOne, pfAwapIds, swapIds);
    }

    function testShouldNotCloseSwapIncorrectHypotheticalInterestCase2() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, 2 * TestConstants.USD_28_000_6DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_userTwo);
        uint256 swap1 = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), 1424808195385802);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC
        );
        vm.warp(30 days);

        uint256[] memory pfAwapIds = new uint256[](0);
        uint256[] memory swapIds = new uint256[](1);
        swapIds[0] = swap1;
        vm.prank(_userTwo);
        vm.expectRevert("IPOR_343");
        _iporProtocol.ammCloseSwapService.closeSwapsUsdt(_userOne, pfAwapIds, swapIds);
    }

    //TODO: after fix review that test and slit in case when fail and pass
    function testShouldPassUsdt() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, 2 * TestConstants.USD_28_000_6DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_userTwo);
        uint256 swap1 = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), 1424808295385802);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC
        );

        uint256[] memory pfAwapIds = new uint256[](0);
        uint256[] memory swapIds = new uint256[](1);
        swapIds[0] = swap1;
        vm.warp(118 days);
        vm.prank(_userTwo);
        vm.expectRevert("IPOR_343");
        _iporProtocol.ammCloseSwapService.closeSwapsUsdt(_userOne, pfAwapIds, swapIds);
    }

    //TODO: after fix review that test and slit in case when fail and pass
    function testShouldPassDai() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, 2 * TestConstants.USD_28_000_18DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_5_18DEC);

        vm.prank(_userTwo);
        uint256 swap1 = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            0,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), 1424808295385802);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC,
            0,
            TestConstants.LEVERAGE_18DEC
        );

        uint256[] memory pfAwapIds = new uint256[](0);
        uint256[] memory swapIds = new uint256[](1);
        swapIds[0] = swap1;
        vm.warp(118 days);
        vm.prank(_userTwo);
        vm.expectRevert("IPOR_343");
        _iporProtocol.ammCloseSwapService.closeSwapsDai(_userOne, pfAwapIds, swapIds);
    }

    function testShouldNotCloseSwapBecauseTotalNotionalMultiplyAverageInterestRateIsTooLow() public {
        // given
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, 2 * TestConstants.USD_28_000_6DEC);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_1_18DEC);

        vm.prank(_userTwo);
        uint256 swap1 = _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_10_000_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC
        );

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), 0);

        vm.prank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysUsdt(
            _userTwo,
            TestConstants.TC_TOTAL_AMOUNT_100_6DEC,
            0,
            TestConstants.LEVERAGE_18DEC
        );
        vm.warp(30 days);

        uint256[] memory pfAwapIds = new uint256[](0);
        uint256[] memory swapIds = new uint256[](1);
        swapIds[0] = swap1;

        vm.prank(_userTwo);
        vm.expectRevert("IPOR_342");
        _iporProtocol.ammCloseSwapService.closeSwapsUsdt(_userOne, pfAwapIds, swapIds);
    }
}
