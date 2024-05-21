// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/console2.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../../contracts/libraries/math/IporMath.sol";
import "../../../contracts/libraries/ProvideLiquidityEvents.sol";

import "../../../contracts/libraries/errors/AmmErrors.sol";
import "../../../contracts/libraries/errors/AmmPoolsErrors.sol";
import {IAmmPoolsServiceUsdc} from "../../../contracts/chains/arbitrum/interfaces/IAmmPoolsServiceUsdc.sol";
import {IAmmPoolsLens} from "../../../contracts/interfaces/IAmmPoolsLens.sol";
import {IAmmGovernanceService} from "../../../contracts/interfaces/IAmmGovernanceService.sol";
import {UsdcTestForkCommonArbitrum} from "./UsdcTestForkCommonArbitrum.sol";

contract ProvideUsdcArbitrumTest is UsdcTestForkCommonArbitrum {
    address userOne;

    uint256 public constant T_ASSET_DECIMALS = 1e6;

    function setUp() public {
        _init();
        userOne = _getUserAddress(22);
        _setupUser(userOne, 100_000 * T_ASSET_DECIMALS);
    }

    function testShouldExchangeRateBe1WhenNoProvideUsdc() external {
        //given

        //when
        uint exchangeRate = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(USDC);
        //then
        assertEq(exchangeRate, 1e18, "exchangeRate should be 1");
    }

    function testShouldRevertWhen0Amount() external {
        // given

        uint userUsdcBalanceBefore = IERC20(USDC).balanceOf(userOne);
        uint userIpUsdcBalanceBefore = IERC20(ipUsdc).balanceOf(userOne);

        // when
        vm.expectRevert(bytes(AmmPoolsErrors.IP_TOKEN_MINT_AMOUNT_TOO_LOW));
        IAmmPoolsServiceUsdc(iporProtocolRouterProxy).provideLiquidityUsdcToAmmPoolUsdc(userOne, 0);

        // then
        uint userUsdcBalanceAfter = IERC20(USDC).balanceOf(userOne);
        uint userIpUsdcBalanceAfter = IERC20(ipUsdc).balanceOf(userOne);

        assertEq(userUsdcBalanceBefore, userUsdcBalanceAfter, "user balance of usdc should not change");
        assertEq(userIpUsdcBalanceBefore, userIpUsdcBalanceAfter, "user ipusdc balance should not change");
    }

    function testShouldRevertWhenBeneficiaryIs0Address() external {
        // given
        uint userUsdcBalanceBefore = IERC20(USDC).balanceOf(userOne);
        uint userIpUsdcBalanceBefore = IERC20(ipUsdc).balanceOf(userOne);
        uint provideAmount = 100 * T_ASSET_DECIMALS;

        // when
        vm.prank(userOne);
        vm.expectRevert(bytes("ERC20: mint to the zero address"));
        IAmmPoolsServiceUsdc(iporProtocolRouterProxy).provideLiquidityUsdcToAmmPoolUsdc(address(0), provideAmount);

        // then
        uint userUsdcBalanceAfter = IERC20(USDC).balanceOf(userOne);
        uint userIpUsdcBalanceAfter = IERC20(ipUsdc).balanceOf(userOne);

        assertEq(userUsdcBalanceBefore, userUsdcBalanceAfter, "user balance of stEth should not change");
        assertEq(userIpUsdcBalanceBefore, userIpUsdcBalanceAfter, "user ipstEth balance should not change");
    }

    function testShouldProvideStEthToOwnAddressWhenBeneficiaryIsSender() external {
        // given
        uint userUsdcBalanceBefore = IERC20(USDC).balanceOf(userOne);
        uint userIpUsdcBalanceBefore = IERC20(ipUsdc).balanceOf(userOne);
        uint ammTreasuryUsdcBalanceBefore = IERC20(USDC).balanceOf(ammTreasuryUsdcProxy);
        uint provideAmount = 100 * T_ASSET_DECIMALS;
        uint256 wadProvideAmount = 100 * PROTOCOL_DECIMALS;
        uint exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(USDC);

        // when
        vm.prank(userOne);
        IAmmPoolsServiceUsdc(iporProtocolRouterProxy).provideLiquidityUsdcToAmmPoolUsdc(userOne, provideAmount);

        // then
        uint userUsdcBalanceAfter = IERC20(USDC).balanceOf(userOne);
        uint userIpUsdcBalanceAfter = IERC20(ipUsdc).balanceOf(userOne);
        uint ammTreasuryUsdcBalanceAfter = IERC20(USDC).balanceOf(ammTreasuryUsdcProxy);

        uint exchangeRateAfter = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(USDC);

        assertApproxEqAbs(userUsdcBalanceBefore - provideAmount, userUsdcBalanceAfter, 10, "user balance of usdc should decrease");
        assertEq(
            userIpUsdcBalanceBefore + wadProvideAmount,
            userIpUsdcBalanceAfter,
            "user ipstEth balance should increase"
        );
        assertEq(userIpUsdcBalanceAfter, wadProvideAmount, "user ipUsdc balance should be equal to provideAmount");
        assertApproxEqAbs(
            ammTreasuryUsdcBalanceBefore,
            10000 * 1e6,
            10,
            "amm treasury balance should be 9999999"
        );
        assertEq(
            ammTreasuryUsdcBalanceAfter,
            10100000000,
            "amm treasury balance should be 10100000000"
        );
        assertEq(exchangeRateBefore, exchangeRateAfter, "exchangeRate should not change");
    }

    function testShouldProvideUsdcToOtherAddressWhenBeneficiaryIsNotSender() external {
        // given
        address userTwo = _getUserAddress(33);
        _setupUser(userTwo, 100_000 * T_ASSET_DECIMALS);

        uint userOneUsdcBalanceBefore = IERC20(USDC).balanceOf(userOne);
        uint userOneIpUsdcBalanceBefore = IERC20(ipUsdc).balanceOf(userOne);
        uint userTwoUsdcBalanceBefore = IERC20(USDC).balanceOf(userTwo);
        uint userTwoIpUsdcBalanceBefore = IERC20(ipUsdc).balanceOf(userTwo);
        uint ammTreasuryUsdcBalanceBefore = IERC20(USDC).balanceOf(ammTreasuryUsdcProxy);

        uint provideAmount = 100 * T_ASSET_DECIMALS;
        uint256 wadProvideAmount = 100 * PROTOCOL_DECIMALS;
        uint exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(USDC);

        // when
        vm.prank(userOne);
        IAmmPoolsServiceUsdc(iporProtocolRouterProxy).provideLiquidityUsdcToAmmPoolUsdc(userTwo, provideAmount);

        // then
        uint userOneUsdcBalanceAfter = IERC20(USDC).balanceOf(userOne);
        uint userOneIpUsdcBalanceAfter = IERC20(ipUsdc).balanceOf(userOne);
        uint userTwoUsdcBalanceAfter = IERC20(USDC).balanceOf(userTwo);
        uint userTwoIpUsdcBalanceAfter = IERC20(ipUsdc).balanceOf(userTwo);
        uint ammTreasuryUsdcBalanceAfter = IERC20(USDC).balanceOf(ammTreasuryUsdcProxy);
        uint exchangeRateAfter = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(USDC);

        assertApproxEqAbs(
            userOneUsdcBalanceBefore - provideAmount,
            userOneUsdcBalanceAfter,
            10,
            "user balance of usdc should decrease"
        );
        assertEq(userOneIpUsdcBalanceBefore, userOneIpUsdcBalanceAfter, "user ipUsdc balance should not change");
        assertEq(userTwoUsdcBalanceBefore, userTwoUsdcBalanceAfter, "user balance of usdc should not change");
        assertEq(
            userTwoIpUsdcBalanceBefore + wadProvideAmount,
            userTwoIpUsdcBalanceAfter,
            "user ipusdc balance should increase"
        );
        assertEq(userTwoIpUsdcBalanceAfter, wadProvideAmount, "user ipusdc balance should be equal to provideAmount");
        assertEq(
            ammTreasuryUsdcBalanceBefore,
            10000 * 1e6,
            "amm treasury balance should be 10000000"
        );
        assertApproxEqAbs(
            ammTreasuryUsdcBalanceAfter,
            10100000000,
            10,
            "amm treasury balance should be 110000000"
        );
        assertEq(exchangeRateBefore, exchangeRateAfter, "exchangeRate should not change");
    }

    function testShouldProvide10TimesUsdc() external {
        // given

        address userTwo = _getUserAddress(33);
        _setupUser(userTwo, 100_000 * T_ASSET_DECIMALS);

        uint userOneUsdcBalanceBefore = IERC20(USDC).balanceOf(userOne);
        uint userOneIpUsdcBalanceBefore = IERC20(ipUsdc).balanceOf(userOne);
        uint userTwoUsdcBalanceBefore = IERC20(USDC).balanceOf(userTwo);
        uint userTwoIpUsdcBalanceBefore = IERC20(ipUsdc).balanceOf(userTwo);
        uint ammTreasuryUsdcBalanceBefore = IERC20(USDC).balanceOf(ammTreasuryUsdcProxy);

        uint provideAmount = 10 * T_ASSET_DECIMALS;
        uint256 wadProvideAmount = 10 * PROTOCOL_DECIMALS;
        uint exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(USDC);

        // when
        for (uint i; i < 10; ++i) {
            vm.prank(userOne);
            IAmmPoolsServiceUsdc(iporProtocolRouterProxy).provideLiquidityUsdcToAmmPoolUsdc(userOne, provideAmount);
            vm.prank(userTwo);
            IAmmPoolsServiceUsdc(iporProtocolRouterProxy).provideLiquidityUsdcToAmmPoolUsdc(userTwo, provideAmount);
        }

        // then
        uint userOneUsdcBalanceAfter = IERC20(USDC).balanceOf(userOne);
        uint userOneIpUsdcBalanceAfter = IERC20(ipUsdc).balanceOf(userOne);
        uint userTwoUsdcBalanceAfter = IERC20(USDC).balanceOf(userTwo);
        uint userTwoIpUsdcBalanceAfter = IERC20(ipUsdc).balanceOf(userTwo);
        uint ammTreasuryUsdcBalanceAfter = IERC20(USDC).balanceOf(ammTreasuryUsdcProxy);
        uint exchangeRateAfter = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(USDC);

        assertApproxEqAbs(
            userOneUsdcBalanceBefore,
            99999999999,
            10,
            "user balance of Usdc should be 99999999999"
        );
        assertApproxEqAbs(
            userOneUsdcBalanceAfter,
            99900000000,
            10,
            "user balance of Usdc should be 99900000000"
        );
        assertEq(
            userOneIpUsdcBalanceBefore + wadProvideAmount * 10,
            userOneIpUsdcBalanceAfter,
            "user ipUsdc balance should increase"
        );
        assertApproxEqAbs(
            userTwoUsdcBalanceBefore,
            99999999999,
            10,
            "user balance of Usdc should be 99999999999"
        );
        assertApproxEqAbs(
            userTwoUsdcBalanceAfter,
            99900000000,
            10,
            "user balance of Usdc should be 99900000000"
        );
        assertEq(
            userTwoIpUsdcBalanceBefore + wadProvideAmount * 10,
            userTwoIpUsdcBalanceAfter,
            "user ipUsdc balance should increase"
        );
        assertEq(exchangeRateBefore, exchangeRateAfter, "exchangeRate should not change");
        assertApproxEqAbs(
            ammTreasuryUsdcBalanceBefore,
            10000 * 1e6,
            10,
            "amm treasury balance should be 10000 * 1e6"
        );
        assertEq(
            ammTreasuryUsdcBalanceAfter,
            10200000000,
            "amm treasury balance should be 10200000000"
        );
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolBalanceExceeded() public {
        // given
        uint256 provideAmount = 20_001 * T_ASSET_DECIMALS;
        vm.startPrank(PROTOCOL_OWNER);
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(USDC, 20_000, 0, 5000);
        vm.stopPrank();

        // when other user provides liquidity
        vm.prank(userOne);
        vm.expectRevert(bytes(AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH));
        IAmmPoolsServiceUsdc(iporProtocolRouterProxy).provideLiquidityUsdcToAmmPoolUsdc(userOne, provideAmount);
    }

    function testShouldEmitprovideLiquidityUsdcToAmmPoolUsdcBeneficiaryIsNotSender() public {
        // given
        address userTwo = _getUserAddress(33);

        uint256 provideAmount = 100 * T_ASSET_DECIMALS;
        uint256 wadProvideAmount = 100 * PROTOCOL_DECIMALS;
        uint exchangeRateBefore = IAmmPoolsLens(iporProtocolRouterProxy).getIpTokenExchangeRate(USDC);
        uint256 ipTokenAmount = IporMath.division(wadProvideAmount * PROTOCOL_DECIMALS, exchangeRateBefore);

        vm.prank(userOne);
        vm.expectEmit(true, true, true, true);
        //then
        emit ProvideLiquidityEvents.ProvideLiquidity(
            USDC,
            userOne,
            userTwo,
            ammTreasuryUsdcProxy,
            exchangeRateBefore,
            wadProvideAmount,
            ipTokenAmount
        );
        // when
        IAmmPoolsServiceUsdc(iporProtocolRouterProxy).provideLiquidityUsdcToAmmPoolUsdc(userTwo, provideAmount);
    }

    function testShouldEmitRedeemUsdcBeneficiaryIsNotSender() public {
        // given
        address userTwo = _getUserAddress(33);

        uint256 provideAmount = 100 * T_ASSET_DECIMALS;
        uint256 wadProvideAmount = 100 * PROTOCOL_DECIMALS;

        uint256 redeemedAmountUsdc = 99500000000000000000;
        uint256 ipTokenAmount = 100000000000000000000;

        vm.prank(userOne);
        IAmmPoolsServiceUsdc(iporProtocolRouterProxy).provideLiquidityUsdcToAmmPoolUsdc(userTwo, provideAmount);

        uint exchangeRate = 1000000000000000000;

        uint256 userTwoIpTokenBalance = IERC20(ipUsdc).balanceOf(userTwo);

        vm.prank(userTwo);
        vm.expectEmit(true, true, true, true);
        //then
        emit ProvideLiquidityEvents.Redeem(
            USDC,
            ammTreasuryUsdcProxy,
            userTwo,
            userOne,
            exchangeRate,
            userTwoIpTokenBalance,
            redeemedAmountUsdc,
            ipTokenAmount
        );

        //when
        IAmmPoolsServiceUsdc(iporProtocolRouterProxy).redeemFromAmmPoolUsdc(userOne, userTwoIpTokenBalance);
    }

    function testShouldRevertBecauseUserOneDoesntHaveIpUsdcTokensToRedeem() public {
        address userTwo = _getUserAddress(33);
        _setupUser(userTwo, 100_000 * T_ASSET_DECIMALS);

        uint provideAmount = 100 * T_ASSET_DECIMALS;
        uint256 ipTokenAmount = 100 * PROTOCOL_DECIMALS;

        vm.prank(userOne);
        IAmmPoolsServiceUsdc(iporProtocolRouterProxy).provideLiquidityUsdcToAmmPoolUsdc(userTwo, provideAmount);

        /// @dev userOne provide liquidity on behalf of userTwo
        vm.prank(userOne);
        //then
        vm.expectRevert(bytes(AmmPoolsErrors.CANNOT_REDEEM_IP_TOKEN_TOO_LOW));
        //when
        IAmmPoolsServiceUsdc(iporProtocolRouterProxy).redeemFromAmmPoolUsdc(userTwo, ipTokenAmount);
    }

    function testShouldRevertWhenProvideLiquidityDirectlyOnService() public {
        //given
        address userTwo = _getUserAddress(33);
        uint provideAmount = 100 * T_ASSET_DECIMALS;

        vm.prank(userOne);
        //then
        vm.expectRevert(bytes(AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH));
        //when
        IAmmPoolsServiceUsdc(ammPoolsServiceUsdc).provideLiquidityUsdcToAmmPoolUsdc(userTwo, provideAmount);
    }
}
