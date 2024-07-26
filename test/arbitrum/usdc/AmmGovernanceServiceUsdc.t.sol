// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAmmPoolsServiceUsdc} from "../../../contracts/chains/arbitrum/interfaces/IAmmPoolsServiceUsdc.sol";
import {IAmmGovernanceService} from "../../../contracts/interfaces/IAmmGovernanceService.sol";
import {IAmmTreasuryBaseV2} from "../../../contracts/base/amm/AmmTreasuryBaseV2.sol";
import {UsdcTestForkCommonArbitrum} from "./UsdcTestForkCommonArbitrum.sol";


contract AmmGovernanceServiceUsdcTest is UsdcTestForkCommonArbitrum {
    address userOne;

    uint256 public constant T_ASSET_DECIMALS = 1e6;

    function setUp() public {
        _init();
        userOne = _getUserAddress(22);
        _setupUser(userOne, 100_000 * T_ASSET_DECIMALS);
    }

    function testShouldWithdrawAllFromAssetManagementUsdc() public {
        //given
        // given
        address userTwo = _getUserAddress(33);
        _setupUser(userTwo, 100_000 * T_ASSET_DECIMALS);


        uint provideAmount = 10000 * T_ASSET_DECIMALS;
        uint256 wadProvideAmount = 10000 * PROTOCOL_DECIMALS;

        vm.prank(PROTOCOL_OWNER);
        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(USDC, 1000000000, 1, 100);

        vm.prank(userOne);
        IAmmPoolsServiceUsdc(iporProtocolRouterProxy).provideLiquidityUsdcToAmmPoolUsdc(userTwo, provideAmount);

        uint256 ammTreasuryUsdcBalanceBefore = IERC20(USDC).balanceOf(ammTreasuryUsdcProxy);
        uint256 ammAssetManagementUsdcBalanceBefore = IERC20(USDC).balanceOf(ammAssetManagementUsdc);
        uint256 liquidityPoolBalanceBefore = IAmmTreasuryBaseV2(ammTreasuryUsdcProxy).getLiquidityPoolBalance();

        // when
        vm.prank(PROTOCOL_OWNER);
        IAmmGovernanceService(iporProtocolRouterProxy).withdrawAllFromAssetManagement(USDC);

        //then
        uint256 ammTreasuryUsdcBalanceAfter = IERC20(USDC).balanceOf(ammTreasuryUsdcProxy);
        uint256 ammAssetManagementUsdcBalanceAfter = IERC20(USDC).balanceOf(ammAssetManagementUsdc);
        uint256 liquidityPoolBalanceAfter = IAmmTreasuryBaseV2(ammTreasuryUsdcProxy).getLiquidityPoolBalance();

        assertEq(ammAssetManagementUsdcBalanceBefore, 19_800 * 1e6);
        assertEq(ammTreasuryUsdcBalanceBefore, 200 * 1e6); /// @dev 1% stay on amm treasury

        assertEq(ammAssetManagementUsdcBalanceAfter, 0);
        assertEq(ammTreasuryUsdcBalanceAfter, 20_000 * 1e6); /// @dev everything withdrawn from amm asset management stays on amm treasury

        assertEq(liquidityPoolBalanceBefore, liquidityPoolBalanceAfter);
    }
}