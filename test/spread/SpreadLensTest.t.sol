// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;


import "../TestCommons.sol";
import "../../contracts/amm/spread/SpreadRouter.sol";
import "./SpreadBaseTestUtils.sol";


contract SpreadRouterTest is SpreadBaseTestUtils {

    address internal _spreadRouter;

    function setUp() public {
        (MockTestnetToken dai,MockTestnetToken usdc,MockTestnetToken usdt) = _getStables();
        _dai = address(dai);
        _usdc = address(usdc);
        _usdt = address(usdt);
        _spreadRouter = _createSpread(_dai, _usdc, _usdt);

    }

    function testShouldReturnSupportedAssets() public {
        // given
        // when
        address[] memory supportedAssets = ISpread28DaysLens(_spreadRouter).getSupportedAssets();

        // then
        assertEq(_dai, supportedAssets[0], "dai address should be the same");
        assertEq(_usdc, supportedAssets[1], "usdc address should be the same");
        assertEq(_usdt, supportedAssets[2], "usdt address should be the same");
    }


}