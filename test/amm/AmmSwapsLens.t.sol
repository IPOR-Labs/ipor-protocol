// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../TestCommons.sol";
import "../utils/TestConstants.sol";
import "contracts/mocks/tokens/MockTestnetToken.sol";
import "contracts/tokens/IpToken.sol";
import "contracts/interfaces/types/IporTypes.sol";

contract AmmSwapsLensTest is TestCommons {
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

    function testGetOpenSwapConfigurationSimpleCase() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 liquidityAmount = 1_000_000 * 1e18;

        _iporProtocol.asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_admin, liquidityAmount);

        //when
        IAmmSwapsLens.OpenSwapConfiguration memory openSwapCfg = _iporProtocol.ammSwapsLens.getOpenSwapConfiguration(
            address(_iporProtocol.asset),
            IporTypes.SwapTenor.DAYS_28
        );

        //then
        assertEq(openSwapCfg.openingFeeRate, 1e16);
        assertEq(openSwapCfg.iporPublicationFeeAmount, 10 * 1e18);
        assertEq(openSwapCfg.liquidationDepositAmount, 25);
        assertEq(openSwapCfg.minLeverage, 10 * 1e18);

        assertEq(openSwapCfg.maxCollateralRatioPayFixed, 48e16);
        assertEq(openSwapCfg.maxCollateralRatioReceiveFixed, 48e16);

        assertEq(openSwapCfg.spreadPayFixed, 1e15);
        assertEq(openSwapCfg.spreadReceiveFixed, 1e15);

        assertEq(openSwapCfg.maxLeveragePayFixed, 1000 * 1e18);
        assertEq(openSwapCfg.maxLeverageReceiveFixed, 1000 * 1e18);

        assertEq(openSwapCfg.maxLiquidityPoolBalance, 1_000_000_000 * 1e18);
        assertEq(openSwapCfg.maxLpAccountContribution, 1_000_000_000 * 1e18);
    }
}
