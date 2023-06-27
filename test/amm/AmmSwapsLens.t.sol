// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../TestCommons.sol";
import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";

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

    function testGetOpenSwapRiskIndicatorsPayFixedSimpleCase() public {
        // given
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        uint256 liquidityAmount = 1_000_000 * 1e18;

        _iporProtocol.asset.approve(address(_iporProtocol.router), liquidityAmount);
        _iporProtocol.ammPoolsService.provideLiquidityDai(_admin, liquidityAmount);

        //when
        AmmTypes.OpenSwapRiskIndicators memory openSwapCfg = _iporProtocol.ammSwapsLens.getOpenSwapRiskIndicators(
            address(_iporProtocol.asset),
            0,
            IporTypes.SwapTenor.DAYS_28
        );

        //then
        assertEq(openSwapCfg.maxCollateralRatio, 9 * 1e17, "maxCollateralRatio");
        assertEq(openSwapCfg.maxCollateralRatioPerLeg, 48 * 1e16, "maxCollateralRatioPerLeg");
        assertEq(openSwapCfg.maxLeveragePerLeg, 1000 * 1e18, "maxLeveragePerLeg");
        assertEq(openSwapCfg.baseSpread, 1e15, "spread");
        assertEq(openSwapCfg.fixedRateCap, 2e16, "fixedRateCap");
    }
}
