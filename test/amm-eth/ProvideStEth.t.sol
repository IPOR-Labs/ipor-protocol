// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "./TestEthMarketCommons.sol";
import "../../contracts/libraries/errors/AmmErrors.sol";

contract ProvideStEthTest is TestEthMarketCommons {
    event ProvideLiquidityStEth(
        uint256 timestamp,
        address from,
        address beneficiary,
        address to,
        uint256 exchangeRate,
        uint256 assetAmount,
        uint256 ipTokenAmount
    );

    event RedeemStEth(
        uint256 timestamp,
        address ammTreasuryEth,
        address from,
        address beneficiary,
        uint256 exchangeRate,
        uint256 amountStEth,
        uint256 redeemedAmountStEth,
        uint256 ipTokenAmount
    );

    function setUp() public {
        vm.createSelectFork(vm.envString("PROVIDER_URL"), 17810000);
        _init();
    }

    function testShouldExchangeRateBe1WhenNoProvideStEth() external {
        //given

        //when
        uint exchangeRate = IAmmPoolsLensEth(iporProtocolRouter).getIpstEthExchangeRate();
        //then
        assertEq(exchangeRate, 1e18, "exchangeRate should be 1");
    }

    function testShouldRevertWhen0Amount() external {
        // given
        uint userStEthBalanceBefore = IStETH(stEth).balanceOf(userOne);
        uint userIpstEthBalanceBefore = IERC20(ipstEth).balanceOf(userOne);

        // when
        vm.expectRevert(bytes(AmmPoolsErrors.IP_TOKEN_MINT_AMOUNT_TOO_LOW));
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityStEth(userOne, 0);

        // then
        uint userStEthBalanceAfter = IStETH(stEth).balanceOf(userOne);
        uint userIpstEthBalanceAfter = IERC20(ipstEth).balanceOf(userOne);

        assertEq(userStEthBalanceBefore, userStEthBalanceAfter, "user balance of stEth should not change");
        assertEq(userIpstEthBalanceBefore, userIpstEthBalanceAfter, "user ipstEth balance should not change");
    }

    function testShouldRevertWhenBeneficiaryIs0Address() external {
        // given
        uint userStEthBalanceBefore = IStETH(stEth).balanceOf(userOne);
        uint userIpstEthBalanceBefore = IERC20(ipstEth).balanceOf(userOne);
        uint provideAmount = 100e18;

        // when
        vm.prank(userOne);
        vm.expectRevert(bytes("ERC20: mint to the zero address"));
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityStEth(address(0), provideAmount);

        // then
        uint userStEthBalanceAfter = IStETH(stEth).balanceOf(userOne);
        uint userIpstEthBalanceAfter = IERC20(ipstEth).balanceOf(userOne);

        assertEq(userStEthBalanceBefore, userStEthBalanceAfter, "user balance of stEth should not change");
        assertEq(userIpstEthBalanceBefore, userIpstEthBalanceAfter, "user ipstEth balance should not change");
    }

    function testShouldProvideStEthToOwnAddressWhenBeneficiaryIsSender() external {
        // given
        uint userStEthBalanceBefore = IStETH(stEth).balanceOf(userOne);
        uint userIpstEthBalanceBefore = IERC20(ipstEth).balanceOf(userOne);
        uint ammTreasuryStEthBalanceBefore = IStETH(stEth).balanceOf(ammTreasuryEth);

        uint provideAmount = 100e18;
        uint exchangeRateBefore = IAmmPoolsLensEth(iporProtocolRouter).getIpstEthExchangeRate();

        // when
        vm.prank(userOne);
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityStEth(userOne, provideAmount);

        // then
        uint userStEthBalanceAfter = IStETH(stEth).balanceOf(userOne);
        uint userIpstEthBalanceAfter = IERC20(ipstEth).balanceOf(userOne);
        uint ammTreasuryStEthBalanceAfter = IStETH(stEth).balanceOf(ammTreasuryEth);

        uint exchangeRateAfter = IAmmPoolsLensEth(iporProtocolRouter).getIpstEthExchangeRate();

        assertEq(
            userStEthBalanceBefore - provideAmount,
            userStEthBalanceAfter,
            "user balance of stEth should decrease"
        );
        assertEq(
            userIpstEthBalanceBefore + provideAmount,
            userIpstEthBalanceAfter,
            "user ipstEth balance should increase"
        );
        assertEq(userIpstEthBalanceAfter, provideAmount, "user ipstEth balance should be equal to provideAmount");
        assertEq(ammTreasuryStEthBalanceBefore, 0, "amm treasury balance should be 0");
        assertEq(
            ammTreasuryStEthBalanceAfter,
            99999999999999999999,
            "amm treasury balance should be 99999999999999999999"
        );
        assertEq(exchangeRateBefore, exchangeRateAfter, "exchangeRate should not change");
    }

    function testShouldProvideStEthToOtherAddressWhenBeneficiaryIsNotSender() external {
        // given
        uint userOneStEthBalanceBefore = IStETH(stEth).balanceOf(userOne);
        uint userOneIpstEthBalanceBefore = IERC20(ipstEth).balanceOf(userOne);
        uint userTwoStEthBalanceBefore = IStETH(stEth).balanceOf(userTwo);
        uint userTwoIpstEthBalanceBefore = IERC20(ipstEth).balanceOf(userTwo);
        uint ammTreasuryStEthBalanceBefore = IStETH(stEth).balanceOf(ammTreasuryEth);

        uint provideAmount = 100e18;
        uint exchangeRateBefore = IAmmPoolsLensEth(iporProtocolRouter).getIpstEthExchangeRate();

        // when
        vm.prank(userOne);
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityStEth(userTwo, provideAmount);

        // then
        uint userOneStEthBalanceAfter = IStETH(stEth).balanceOf(userOne);
        uint userOneIpstEthBalanceAfter = IERC20(ipstEth).balanceOf(userOne);
        uint userTwoStEthBalanceAfter = IStETH(stEth).balanceOf(userTwo);
        uint userTwoIpstEthBalanceAfter = IERC20(ipstEth).balanceOf(userTwo);
        uint ammTreasuryStEthBalanceAfter = IStETH(stEth).balanceOf(ammTreasuryEth);
        uint exchangeRateAfter = IAmmPoolsLensEth(iporProtocolRouter).getIpstEthExchangeRate();

        assertEq(
            userOneStEthBalanceBefore - provideAmount,
            userOneStEthBalanceAfter,
            "user balance of stEth should decrease"
        );
        assertEq(userOneIpstEthBalanceBefore, userOneIpstEthBalanceAfter, "user ipstEth balance should not change");
        assertEq(userTwoStEthBalanceBefore, userTwoStEthBalanceAfter, "user balance of stEth should not change");
        assertEq(
            userTwoIpstEthBalanceBefore + provideAmount,
            userTwoIpstEthBalanceAfter,
            "user ipstEth balance should increase"
        );
        assertEq(userTwoIpstEthBalanceAfter, provideAmount, "user ipstEth balance should be equal to provideAmount");
        assertEq(ammTreasuryStEthBalanceBefore, 0, "amm treasury balance should be 0");
        assertEq(
            ammTreasuryStEthBalanceAfter,
            99999999999999999999,
            "amm treasury balance should be 99999999999999999999"
        );
        assertEq(exchangeRateBefore, exchangeRateAfter, "exchangeRate should not change");
    }

    function testShouldProvide10TimesStEth() external {
        // given
        uint userOneStEthBalanceBefore = IStETH(stEth).balanceOf(userOne);
        uint userOneIpstEthBalanceBefore = IERC20(ipstEth).balanceOf(userOne);
        uint userTwoStEthBalanceBefore = IStETH(stEth).balanceOf(userTwo);
        uint userTwoIpstEthBalanceBefore = IERC20(ipstEth).balanceOf(userTwo);
        uint ammTreasuryStEthBalanceBefore = IStETH(stEth).balanceOf(ammTreasuryEth);

        uint provideAmount = 10e18;
        uint exchangeRateBefore = IAmmPoolsLensEth(iporProtocolRouter).getIpstEthExchangeRate();

        // when
        for (uint i; i < 10; ++i) {
            vm.prank(userOne);
            IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityStEth(userOne, provideAmount);
            vm.prank(userTwo);
            IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityStEth(userTwo, provideAmount);
        }

        // then
        uint userOneStEthBalanceAfter = IStETH(stEth).balanceOf(userOne);
        uint userOneIpstEthBalanceAfter = IERC20(ipstEth).balanceOf(userOne);
        uint userTwoStEthBalanceAfter = IStETH(stEth).balanceOf(userTwo);
        uint userTwoIpstEthBalanceAfter = IERC20(ipstEth).balanceOf(userTwo);
        uint ammTreasuryStEthBalanceAfter = IStETH(stEth).balanceOf(ammTreasuryEth);
        uint exchangeRateAfter = IAmmPoolsLensEth(iporProtocolRouter).getIpstEthExchangeRate();

        assertEq(
            userOneStEthBalanceBefore,
            49999999999999999999999,
            "user balance of stEth should be 49999999999999999999999"
        );
        assertEq(
            userOneStEthBalanceAfter,
            49900000000000000000009,
            "user balance of stEth should be 49999999999999999999999"
        );
        assertEq(
            userOneIpstEthBalanceBefore + provideAmount * 10,
            userOneIpstEthBalanceAfter,
            "user ipstEth balance should increase"
        );
        assertEq(
            userTwoStEthBalanceBefore,
            49999999999999999999999,
            "user balance of stEth should be 49999999999999999999999"
        );
        assertEq(
            userTwoStEthBalanceAfter,
            49900000000000000000009,
            "user balance of stEth should be 49999999999999999999999"
        );
        assertEq(
            userTwoIpstEthBalanceBefore + provideAmount * 10,
            userTwoIpstEthBalanceAfter,
            "user ipstEth balance should increase"
        );
        assertEq(exchangeRateBefore, exchangeRateAfter, "exchangeRate should not change");
        assertEq(ammTreasuryStEthBalanceBefore, 0, "amm treasury balance should be 0");
        assertEq(
            ammTreasuryStEthBalanceAfter,
            199999999999999999979,
            "amm treasury balance should be 199999999999999999979"
        );

        console2.log("IERC20(ipstEth): ", IERC20(ipstEth).totalSupply());
        console2.log(
            "IAmmPoolsLensEth(iporProtocolRouter).getIpstEthExchangeRate(): ",
            IAmmPoolsLensEth(iporProtocolRouter).getIpstEthExchangeRate()
        );
        console2.log("IStETH(stEth).balanceOf(ammTreasuryEth): ", IStETH(stEth).balanceOf(ammTreasuryEth));
        // 49_999 999999999999999999 (userOne Balance)
        //-   100 000000000000000000 (transfer to ammTreasury)
        //-----------------------------
        // 49_900 000000000000000009 (userOne balance after)
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolBalanceExceeded() public {
        // given
        uint provideAmount = 20_001e18;
        vm.startPrank(owner);
        IAmmGovernanceService(iporProtocolRouter).setAmmPoolsParams(stEth, 20_000, 0, 5000);
        vm.stopPrank();

        // when other user provides liquidity
        vm.prank(userOne);
        vm.expectRevert(bytes(AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH));
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityStEth(userOne, provideAmount);
    }

    function testShouldEmitProvideLiquidityStEthBeneficiaryIsNotSender() public {
        // given
        uint provideAmount = 100e18;
        uint exchangeRateBefore = IAmmPoolsLensEth(iporProtocolRouter).getIpstEthExchangeRate();
        uint256 ipTokenAmount = IporMath.division(provideAmount * 1e18, exchangeRateBefore);

        vm.prank(userOne);
        vm.expectEmit(true, true, true, true);
        //then
        emit ProvideLiquidityStEth(
            block.timestamp,
            userOne,
            userTwo,
            ammTreasuryEth,
            exchangeRateBefore,
            provideAmount,
            ipTokenAmount
        );

        // when
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityStEth(userTwo, provideAmount);
    }

    function testShouldEmitRedeemStEthBeneficiaryIsNotSender() public {
        // given
        uint provideAmount = 100e18;
        uint256 amountStEth = 99999999999999999999;
        uint256 redeemedAmountStEth = 99499999999999999999;
        uint256 ipTokenAmount = 99999999999999999999;

        vm.prank(userOne);
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityStEth(userTwo, provideAmount);

        uint exchangeRate = 1000000000000000000;

        vm.prank(userTwo);
        vm.expectEmit(true, true, true, true);
        //then
        emit RedeemStEth(
            block.timestamp,
            ammTreasuryEth,
            userTwo,
            userOne,
            exchangeRate,
            amountStEth,
            redeemedAmountStEth,
            ipTokenAmount
        );

        //when
        IAmmPoolsServiceEth(iporProtocolRouter).redeemFromAmmPoolStEth(userOne, amountStEth);
    }

    function testShouldRevertBecauseUserOneDoesntHaveIpstEthTokensToRedeem() public {
        uint provideAmount = 100e18;
        uint256 amountStEth = 99999999999999999999;

        vm.prank(userOne);
        IAmmPoolsServiceEth(iporProtocolRouter).provideLiquidityStEth(userTwo, provideAmount);

        /// @dev userOne provide liquidity on behalf of userTwo
        vm.prank(userOne);
        //then
        vm.expectRevert(bytes(AmmPoolsErrors.CANNOT_REDEEM_IP_TOKEN_TOO_LOW));

        //when
        IAmmPoolsServiceEth(iporProtocolRouter).redeemFromAmmPoolStEth(userTwo, amountStEth);
    }

    function testShouldRevertWhenProvideLiquidityDirectlyOnService() public {
        //given
        uint provideAmount = 100e18;

        vm.prank(userOne);
        //then
        vm.expectRevert(bytes(AmmErrors.LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH));
        //when
        IAmmPoolsServiceEth(ammPoolsServiceEth).provideLiquidityStEth(userTwo, provideAmount);
    }
}
