// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../../contracts/libraries/math/IporMath.sol";
import "../../../contracts/libraries/ProvideLiquidityEvents.sol";

import "../../../contracts/libraries/errors/AmmErrors.sol";
import "../../../contracts/libraries/errors/AmmPoolsErrors.sol";
import {IAmmPoolsServiceUsdm} from "../../../contracts/amm-usdm/interfaces/IAmmPoolsServiceUsdm.sol";
import {IAmmPoolsLensUsdm} from "../../../contracts/amm-usdm/interfaces/IAmmPoolsLensUsdm.sol";
import {IAmmGovernanceService} from "../../../contracts/interfaces/IAmmGovernanceService.sol";
import {UsdmTestForkCommonEthereum} from "./UsdmTestForkCommonEthereum.sol";

contract ProvideUsdmEthereumTest is UsdmTestForkCommonEthereum {

    address userOne;

    function setUp() public {
        _init();
        userOne = _getUserAddress(22);
        _setupUser(userOne, 100_000 * 1e18);
    }

    function testShouldExchangeRateBe1WhenNoProvideUsdm() external {
        //given

        //when
        uint exchangeRate = IAmmPoolsLensUsdm(IporProtocolRouterProxy).getIpUsdmExchangeRate();
        //then
        assertEq(exchangeRate, 1e18, "exchangeRate should be 1");
    }

    function testShouldRevertWhen0Amount() external {
        // given

        uint userUsdmBalanceBefore = IERC20(USDM).balanceOf(userOne);
        uint userIpUsdmBalanceBefore = IERC20(ipUsdm).balanceOf(userOne);

        // when
        vm.expectRevert(bytes(AmmPoolsErrors.IP_TOKEN_MINT_AMOUNT_TOO_LOW));
        IAmmPoolsServiceUsdm(IporProtocolRouterProxy).provideLiquidityUsdmToAmmPoolUsdm(userOne, 0);

        // then
        uint userUsdmBalanceAfter = IERC20(USDM).balanceOf(userOne);
        uint userIpUsdmBalanceAfter = IERC20(ipUsdm).balanceOf(userOne);

        assertEq(userUsdmBalanceBefore, userUsdmBalanceAfter, "user balance of usdm should not change");
        assertEq(userIpUsdmBalanceBefore, userIpUsdmBalanceAfter, "user ipusdm balance should not change");
    }

    function testShouldRevertWhenBeneficiaryIs0Address() external {
        // given
        uint userUsdmBalanceBefore = IERC20(USDM).balanceOf(userOne);
        uint userIpUsdmBalanceBefore = IERC20(ipUsdm).balanceOf(userOne);
        uint provideAmount = 100e18;

        // when
        vm.prank(userOne);
        vm.expectRevert(bytes("ERC20: mint to the zero address"));
        IAmmPoolsServiceUsdm(IporProtocolRouterProxy).provideLiquidityUsdmToAmmPoolUsdm(address(0), provideAmount);

        // then
        uint userUsdmBalanceAfter = IERC20(USDM).balanceOf(userOne);
        uint userIpUsdmBalanceAfter = IERC20(ipUsdm).balanceOf(userOne);

        assertEq(userUsdmBalanceBefore, userUsdmBalanceAfter, "user balance of stEth should not change");
        assertEq(userIpUsdmBalanceBefore, userIpUsdmBalanceAfter, "user ipstEth balance should not change");
    }

    function testShouldProvideStEthToOwnAddressWhenBeneficiaryIsSender() external {
        // given
        uint userUsdmBalanceBefore = IERC20(USDM).balanceOf(userOne);
        uint userIpUsdmBalanceBefore = IERC20(ipUsdm).balanceOf(userOne);
        uint ammTreasuryUsdmBalanceBefore = IERC20(USDM).balanceOf(ammTreasuryUsdmProxy);
        uint provideAmount = 100e18;
        uint exchangeRateBefore = IAmmPoolsLensUsdm(IporProtocolRouterProxy).getIpUsdmExchangeRate();

        // when
        vm.prank(userOne);
        IAmmPoolsServiceUsdm(IporProtocolRouterProxy).provideLiquidityUsdmToAmmPoolUsdm(userOne, provideAmount);

        // then
        uint userUsdmBalanceAfter = IERC20(USDM).balanceOf(userOne);
        uint userIpUsdmBalanceAfter = IERC20(ipUsdm).balanceOf(userOne);
        uint ammTreasuryUsdmBalanceAfter = IERC20(USDM).balanceOf(ammTreasuryUsdmProxy);

        uint exchangeRateAfter = IAmmPoolsLensUsdm(IporProtocolRouterProxy).getIpUsdmExchangeRate();

        assertEq(userUsdmBalanceBefore - provideAmount, userUsdmBalanceAfter, "user balance of usdm should decrease");
        assertEq(
            userIpUsdmBalanceBefore + provideAmount,
            userIpUsdmBalanceAfter,
            "user ipstEth balance should increase"
        );
        assertEq(userIpUsdmBalanceAfter, provideAmount, "user ipUsdm balance should be equal to provideAmount");
        assertEq(
            ammTreasuryUsdmBalanceBefore,
            9999999999999999999,
            "amm treasury balance should be 9999999999999999999"
        );
        assertEq(
            ammTreasuryUsdmBalanceAfter,
            109999999999999999999,
            "amm treasury balance should be 109999999999999999999"
        );
        assertEq(exchangeRateBefore, exchangeRateAfter, "exchangeRate should not change");
    }

    function testShouldProvideUsdmToOtherAddressWhenBeneficiaryIsNotSender() external {
        // given
        address userTwo = _getUserAddress(33);
        _setupUser(userTwo, 100_000 * 1e18);

        uint userOneUsdmBalanceBefore = IERC20(USDM).balanceOf(userOne);
        uint userOneIpUsdmBalanceBefore = IERC20(ipUsdm).balanceOf(userOne);
        uint userTwoUsdmBalanceBefore = IERC20(USDM).balanceOf(userTwo);
        uint userTwoIpUsdmBalanceBefore = IERC20(ipUsdm).balanceOf(userTwo);
        uint ammTreasuryUsdmBalanceBefore = IERC20(USDM).balanceOf(ammTreasuryUsdmProxy);

        uint provideAmount = 100e18;
        uint exchangeRateBefore = IAmmPoolsLensUsdm(IporProtocolRouterProxy).getIpUsdmExchangeRate();

        // when
        vm.prank(userOne);
        IAmmPoolsServiceUsdm(IporProtocolRouterProxy).provideLiquidityUsdmToAmmPoolUsdm(userTwo, provideAmount);

        // then
        uint userOneUsdmBalanceAfter = IERC20(USDM).balanceOf(userOne);
        uint userOneIpUsdmBalanceAfter = IERC20(ipUsdm).balanceOf(userOne);
        uint userTwoUsdmBalanceAfter = IERC20(USDM).balanceOf(userTwo);
        uint userTwoIpUsdmBalanceAfter = IERC20(ipUsdm).balanceOf(userTwo);
        uint ammTreasuryUsdmBalanceAfter = IERC20(USDM).balanceOf(ammTreasuryUsdmProxy);
        uint exchangeRateAfter = IAmmPoolsLensUsdm(IporProtocolRouterProxy).getIpUsdmExchangeRate();

        assertEq(
            userOneUsdmBalanceBefore - provideAmount,
            userOneUsdmBalanceAfter,
            "user balance of usdm should decrease"
        );
        assertEq(userOneIpUsdmBalanceBefore, userOneIpUsdmBalanceAfter, "user ipUsdm balance should not change");
        assertEq(userTwoUsdmBalanceBefore, userTwoUsdmBalanceAfter, "user balance of usdm should not change");
        assertEq(
            userTwoIpUsdmBalanceBefore + provideAmount,
            userTwoIpUsdmBalanceAfter,
            "user ipusdm balance should increase"
        );
        assertEq(userTwoIpUsdmBalanceAfter, provideAmount, "user ipusdm balance should be equal to provideAmount");
        assertEq(
            ammTreasuryUsdmBalanceBefore,
            9999999999999999999,
            "amm treasury balance should be 10000000000000000000"
        );
        assertEq(
            ammTreasuryUsdmBalanceAfter,
            109999999999999999999,
            "amm treasury balance should be 110000000000000000000"
        );
        assertEq(exchangeRateBefore, exchangeRateAfter, "exchangeRate should not change");
    }

    function testShouldProvide10TimesUsdm() external {
        // given

        address userTwo = _getUserAddress(33);
        _setupUser(userTwo, 100_000 * 1e18);

        uint userOneUsdmBalanceBefore = IERC20(USDM).balanceOf(userOne);
        uint userOneIpUsdmBalanceBefore = IERC20(ipUsdm).balanceOf(userOne);
        uint userTwoUsdmBalanceBefore = IERC20(USDM).balanceOf(userTwo);
        uint userTwoIpUsdmBalanceBefore = IERC20(ipUsdm).balanceOf(userTwo);
        uint ammTreasuryUsdmBalanceBefore = IERC20(USDM).balanceOf(ammTreasuryUsdmProxy);

        uint provideAmount = 10e18;
        uint exchangeRateBefore = IAmmPoolsLensUsdm(IporProtocolRouterProxy).getIpUsdmExchangeRate();

        // when
        for (uint i; i < 10; ++i) {
            vm.prank(userOne);
            IAmmPoolsServiceUsdm(IporProtocolRouterProxy).provideLiquidityUsdmToAmmPoolUsdm(userOne, provideAmount);
            vm.prank(userTwo);
            IAmmPoolsServiceUsdm(IporProtocolRouterProxy).provideLiquidityUsdmToAmmPoolUsdm(userTwo, provideAmount);
        }

        // then
        uint userOneUsdmBalanceAfter = IERC20(USDM).balanceOf(userOne);
        uint userOneIpUsdmBalanceAfter = IERC20(ipUsdm).balanceOf(userOne);
        uint userTwoUsdmBalanceAfter = IERC20(USDM).balanceOf(userTwo);
        uint userTwoIpUsdmBalanceAfter = IERC20(ipUsdm).balanceOf(userTwo);
        uint ammTreasuryUsdmBalanceAfter = IERC20(USDM).balanceOf(ammTreasuryUsdmProxy);
        uint exchangeRateAfter = IAmmPoolsLensUsdm(IporProtocolRouterProxy).getIpUsdmExchangeRate();

        assertEq(
            userOneUsdmBalanceBefore,
            99999999999999999999999,
            "user balance of Usdm should be 99999999999999999999999"
        );
        assertEq(
            userOneUsdmBalanceAfter,
            99900000000000000000006,
            "user balance of Usdm should be 99900000000000000000006"
        );
        assertEq(
            userOneIpUsdmBalanceBefore + provideAmount * 10,
            userOneIpUsdmBalanceAfter,
            "user ipUsdm balance should increase"
        );
        assertEq(
            userTwoUsdmBalanceBefore,
            99999999999999999999999,
            "user balance of Usdm should be 99999999999999999999999"
        );
        assertEq(
            userTwoUsdmBalanceAfter,
            99900000000000000000006,
            "user balance of Usdm should be 99900000000000000000006"
        );
        assertEq(
            userTwoIpUsdmBalanceBefore + provideAmount * 10,
            userTwoIpUsdmBalanceAfter,
            "user ipUsdm balance should increase"
        );
        assertEq(exchangeRateBefore, exchangeRateAfter, "exchangeRate should not change");
        assertEq(
            ammTreasuryUsdmBalanceBefore,
            9999999999999999999,
            "amm treasury balance should be 9999999999999999999"
        );
        assertEq(
            ammTreasuryUsdmBalanceAfter,
            209999999999999999984,
            "amm treasury balance should be 209999999999999999984"
        );
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolBalanceExceeded() public {
        // given
        uint provideAmount = 20_001e18;
        vm.startPrank(IporProtocolOwner);
        IAmmGovernanceService(IporProtocolRouterProxy).setAmmPoolsParams(USDM, 20_000, 0, 5000);
        vm.stopPrank();

        // when other user provides liquidity
        vm.prank(userOne);
        vm.expectRevert(bytes(AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH));
        IAmmPoolsServiceUsdm(IporProtocolRouterProxy).provideLiquidityUsdmToAmmPoolUsdm(userOne, provideAmount);
    }

    function testShouldEmitprovideLiquidityUsdmToAmmPoolUsdmBeneficiaryIsNotSender() public {
        // given
        address userTwo = _getUserAddress(33);

        uint provideAmount = 100e18;
        uint exchangeRateBefore = IAmmPoolsLensUsdm(IporProtocolRouterProxy).getIpUsdmExchangeRate();
        uint256 ipTokenAmount = IporMath.division(provideAmount * 1e18, exchangeRateBefore);

        vm.prank(userOne);
        vm.expectEmit(true, true, true, true);
        //then
        emit ProvideLiquidityEvents.ProvideLiquidity(
            USDM,
            userOne,
            userTwo,
            ammTreasuryUsdmProxy,
            exchangeRateBefore,
            provideAmount,
            ipTokenAmount
        );

        // when
        IAmmPoolsServiceUsdm(IporProtocolRouterProxy).provideLiquidityUsdmToAmmPoolUsdm(userTwo, provideAmount);
    }

    function testShouldEmitRedeemUsdmBeneficiaryIsNotSender() public {
        // given
        address userTwo = _getUserAddress(33);
        uint provideAmount = 100e18;
        uint256 amountUsdm = 99999999999999999999;
        uint256 redeemedAmountUsdm = 99499999999999999999;
        uint256 ipTokenAmount = 99999999999999999999;

        vm.prank(userOne);
        IAmmPoolsServiceUsdm(IporProtocolRouterProxy).provideLiquidityUsdmToAmmPoolUsdm(userTwo, provideAmount);

        uint exchangeRate = 1000000000000000000;

        vm.prank(userTwo);
        vm.expectEmit(true, true, true, true);
        //then
        emit ProvideLiquidityEvents.Redeem(
            USDM,
            ammTreasuryUsdmProxy,
            userTwo,
            userOne,
            exchangeRate,
           amountUsdm,
            redeemedAmountUsdm,
            ipTokenAmount
        );

        //when
        IAmmPoolsServiceUsdm(IporProtocolRouterProxy).redeemFromAmmPoolUsdm(userOne,amountUsdm);
    }

        function testShouldRevertBecauseUserOneDoesntHaveIpUsdmTokensToRedeem() public {
            address userTwo = _getUserAddress(33);
            _setupUser(userTwo, 100_000 * 1e18);

        uint provideAmount = 100e18;
            uint256 amountUsdm = 99999999999999999999;

            vm.prank(userOne);
            IAmmPoolsServiceUsdm(IporProtocolRouterProxy).provideLiquidityUsdmToAmmPoolUsdm(userTwo, provideAmount);

            /// @dev userOne provide liquidity on behalf of userTwo
            vm.prank(userOne);
            //then
            vm.expectRevert(bytes(AmmPoolsErrors.CANNOT_REDEEM_IP_TOKEN_TOO_LOW));

            //when
            IAmmPoolsServiceUsdm(IporProtocolRouterProxy).redeemFromAmmPoolUsdm(userTwo,amountUsdm);
        }

        function testShouldRevertWhenProvideLiquidityDirectlyOnService() public {
            //given
            address userTwo = _getUserAddress(33);
            uint provideAmount = 100e18;

            vm.prank(userOne);
            //then
            vm.expectRevert(bytes(AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH));
            //when
            IAmmPoolsServiceUsdm(ammPoolsServiceUsdm).provideLiquidityUsdmToAmmPoolUsdm(userTwo, provideAmount);
        }

}
