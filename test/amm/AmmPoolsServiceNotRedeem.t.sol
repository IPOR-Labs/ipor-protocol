// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/interfaces/types/IporTypes.sol";

contract AmmPoolsServiceNotRedeem is TestCommons {
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
        _cfg.spread28DaysTestCase = BuilderUtils.Spread28DaysTestCase.CASE5;
    }

    function testShouldNotRedeemWhenLiquidityPoolCollateralRatioAlreadyExceededAndPayFixed() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, 60000 * TestConstants.D18);

        vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            27000 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), 0)
        );
        vm.stopPrank();

        //BEGIN HACK - subtract liquidity without  burn ipToken
        vm.startPrank(address(_iporProtocol.router));
        _iporProtocol.ammStorage.subtractLiquidityInternal(45000 * TestConstants.D18);
        vm.stopPrank();
        //END HACK - subtract liquidity without  burn ipToken

        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );

        uint256 actualCollateral = balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed;
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;

        // when
        vm.prank(_liquidityProvider);
        vm.expectRevert("IPOR_402");
        _iporProtocol.ammPoolsService.redeemFromAmmPoolDai(_liquidityProvider, 60000 * TestConstants.D18);
        assertGt(actualCollateral, actualLiquidityPoolBalance);
    }

    function testShouldNotRedeemWhenLiquidityPoolCollateralRatioAlreadyExceededAndReceiveFixed() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, 60000 * TestConstants.D18);

        vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            27000 * TestConstants.D18,
            TestConstants.D16,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), 1)
        );
        vm.stopPrank();

        //BEGIN HACK - subtract liquidity without  burn ipToken
        vm.startPrank(address(_iporProtocol.router));
        _iporProtocol.ammStorage.subtractLiquidityInternal(45000 * TestConstants.D18);
        vm.stopPrank();
        //END HACK - subtract liquidity without  burn ipToken

        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );

        uint256 actualCollateral = balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed;
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;

        // when
        vm.prank(_liquidityProvider);
        vm.expectRevert("IPOR_402");
        _iporProtocol.ammPoolsService.redeemFromAmmPoolDai(_liquidityProvider, 60000 * TestConstants.D18);
        assertGt(actualCollateral, actualLiquidityPoolBalance);
    }

    function testShouldNotRedeemWhenLiquidityPoolCollateralRatioExceededAndPayFixed() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, 60000 * TestConstants.D18);

        vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapPayFixed28daysDai(
            _userTwo,
            27000 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), 0)
        );
        vm.stopPrank();

        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );

        uint256 actualCollateral = balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed;
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;

        // when
        vm.prank(_liquidityProvider);
        vm.expectRevert("IPOR_402");
        _iporProtocol.ammPoolsService.redeemFromAmmPoolDai(_liquidityProvider, 41000 * TestConstants.D18);
        assertLt(actualCollateral, actualLiquidityPoolBalance);
    }

    function testShouldNotRedeemWhenLiquidityPoolCollateralRatioExceededAndReceiveFixed() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.updateIndex(address(_iporProtocol.asset), TestConstants.PERCENTAGE_3_18DEC);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, 60000 * TestConstants.D18);

        vm.startPrank(_userTwo);
        _iporProtocol.ammOpenSwapService.openSwapReceiveFixed28daysDai(
            _userTwo,
            27000 * TestConstants.D18,
            TestConstants.D16,
            TestConstants.LEVERAGE_18DEC,
            getRiskIndicatorsInputs(address(_iporProtocol.asset), 1)
        );
        vm.stopPrank();

        IporTypes.AmmBalancesMemory memory balance = _iporProtocol.ammPoolsLens.getAmmBalance(
            address(_iporProtocol.asset)
        );

        uint256 actualCollateral = balance.totalCollateralPayFixed + balance.totalCollateralReceiveFixed;
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;

        // when
        vm.prank(_liquidityProvider);
        vm.expectRevert("IPOR_402");
        _iporProtocol.ammPoolsService.redeemFromAmmPoolDai(_liquidityProvider, 41000 * TestConstants.D18);
        assertLt(actualCollateral, actualLiquidityPoolBalance);
    }

    function testShouldNotRedeemIpTokensBecauseOfEmptyLiquidityPool() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_10_000_18DEC);

        vm.prank(address(_iporProtocol.router));
        _iporProtocol.ammStorage.subtractLiquidityInternal(TestConstants.USD_10_000_18DEC);

        // when
        vm.prank(_liquidityProvider);
        vm.expectRevert("IPOR_300");
        _iporProtocol.ammPoolsService.redeemFromAmmPoolDai(_liquidityProvider, TestConstants.USD_1_000_18DEC);
    }

    function testShouldNotRedeemIpTokensBecauseOfEmptyLiquidityPoolAfterRedeemLiquidity() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_liquidityProvider, TestConstants.USD_10_000_18DEC);

        /// @dev hack to decrease ERC20 balance
        vm.prank(address(_iporProtocol.ammTreasury));
        _iporProtocol.asset.transfer(_userOne, TestConstants.USD_10_000_18DEC);

        // when
        vm.prank(_liquidityProvider);
        vm.expectRevert("IPOR_409");
        _iporProtocol.ammPoolsService.redeemFromAmmPoolDai(_liquidityProvider, TestConstants.USD_10_000_18DEC);
    }

    function testShouldNotRedeemIpTokensBecauseRedeemAmountIsTooLow() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_liquidityProvider);
        vm.expectRevert("IPOR_403");
        _iporProtocol.ammPoolsService.redeemFromAmmPoolDai(_liquidityProvider, TestConstants.ZERO);
    }

    function testShouldNotRedeemWhenRoundingToZero6Decimals() public {
        _iporProtocol = _iporProtocolFactory.getUsdtInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.ammPoolsService.provideLiquidityUsdt(_liquidityProvider, TestConstants.USD_10_000_6DEC);

        vm.prank(_liquidityProvider);
        vm.expectRevert("IPOR_405");
        _iporProtocol.ammPoolsService.redeemFromAmmPoolUsdt(_liquidityProvider, 1e11);
    }
}
