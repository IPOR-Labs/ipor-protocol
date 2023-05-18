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


}