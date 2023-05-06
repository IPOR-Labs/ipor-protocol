// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase0MiltonUsdt.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/joseph/MockCase1JosephDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/interfaces/types/IporTypes.sol";

contract JosephNotRedeem is TestCommons, DataUtils, SwapUtils {
    IporProtocolFactory.IporProtocolConfig private _cfg;
    IporProtocolBuilder.IporProtocol internal _iporProtocol;

    function setUp() public {
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);

        _cfg.approvalsForUsers = _users;
        _cfg.iporOracleUpdater = _userOne;
        _cfg.spreadImplementation = address(
            new MockSpreadModel(
                TestConstants.PERCENTAGE_4_18DEC,
                TestConstants.PERCENTAGE_2_18DEC,
                TestConstants.ZERO_INT,
                TestConstants.ZERO_INT
            )
        );
    }

    function testShouldNotRedeemWhenLiquidityPoolUtilizationAlreadyExceededAndPayFixed() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(60000 * TestConstants.D18, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            27000 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        //BEGIN HACK - subtract liquidity without  burn ipToken
        _iporProtocol.miltonStorage.setJoseph(_admin);
        _iporProtocol.miltonStorage.subtractLiquidity(45000 * TestConstants.D18);
        _iporProtocol.miltonStorage.setJoseph(address(_iporProtocol.joseph));
        //END HACK - subtract liquidity without  burn ipToken

        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();

        uint256 actualCollateral = balance.totalCollateralPayFixed +
            balance.totalCollateralReceiveFixed;
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;

        // when
        vm.prank(_liquidityProvider);
        vm.expectRevert("IPOR_402");
        _iporProtocol.joseph.itfRedeem(60000 * TestConstants.D18, block.timestamp);
        assertGt(actualCollateral, actualLiquidityPoolBalance);
    }

    function testShouldNotRedeemWhenLiquidityPoolUtilizationAlreadyExceededAndReceiveFixed()
        public
    {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(60000 * TestConstants.D18, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            27000 * TestConstants.D18,
            TestConstants.D16,
            TestConstants.LEVERAGE_18DEC
        );

        //BEGIN HACK - subtract liquidity without  burn ipToken
        _iporProtocol.miltonStorage.setJoseph(_admin);
        _iporProtocol.miltonStorage.subtractLiquidity(45000 * TestConstants.D18);
        _iporProtocol.miltonStorage.setJoseph(address(_iporProtocol.joseph));
        //END HACK - subtract liquidity without  burn ipToken

        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();

        uint256 actualCollateral = balance.totalCollateralPayFixed +
            balance.totalCollateralReceiveFixed;
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;

        // when
        vm.prank(_liquidityProvider);
        vm.expectRevert("IPOR_402");
        _iporProtocol.joseph.itfRedeem(60000 * TestConstants.D18, block.timestamp);
        assertGt(actualCollateral, actualLiquidityPoolBalance);
    }

    function testShouldNotRedeemWhenLiquidityPoolUtilizationExceededAndPayFixed() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(60000 * TestConstants.D18, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapPayFixed(
            block.timestamp,
            27000 * TestConstants.D18,
            9 * TestConstants.D17,
            TestConstants.LEVERAGE_18DEC
        );

        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();

        uint256 actualCollateral = balance.totalCollateralPayFixed +
            balance.totalCollateralReceiveFixed;
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;

        // when
        vm.prank(_liquidityProvider);
        vm.expectRevert("IPOR_402");
        _iporProtocol.joseph.itfRedeem(41000 * TestConstants.D18, block.timestamp);
        assertLt(actualCollateral, actualLiquidityPoolBalance);
    }

    function testShouldNotRedeemWhenLiquidityPoolUtilizationExceededAndReceiveFixed() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_userOne);
        _iporProtocol.iporOracle.itfUpdateIndex(
            address(_iporProtocol.asset),
            TestConstants.PERCENTAGE_3_18DEC,
            block.timestamp
        );

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(60000 * TestConstants.D18, block.timestamp);

        vm.prank(_userTwo);
        _iporProtocol.milton.itfOpenSwapReceiveFixed(
            block.timestamp,
            27000 * TestConstants.D18,
            TestConstants.D16,
            TestConstants.LEVERAGE_18DEC
        );

        IporTypes.MiltonBalancesMemory memory balance = _iporProtocol.milton.getAccruedBalance();

        uint256 actualCollateral = balance.totalCollateralPayFixed +
            balance.totalCollateralReceiveFixed;
        uint256 actualLiquidityPoolBalance = balance.liquidityPool;

        // when
        vm.prank(_liquidityProvider);
        vm.expectRevert("IPOR_402");
        _iporProtocol.joseph.itfRedeem(41000 * TestConstants.D18, block.timestamp);
        assertLt(actualCollateral, actualLiquidityPoolBalance);
    }

    function testShouldNotRedeemIpTokensBecauseOfEmptyLiquidityPool() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_10_000_18DEC, block.timestamp);
        _iporProtocol.miltonStorage.setJoseph(_userOne);

        vm.prank(_userOne);
        _iporProtocol.miltonStorage.subtractLiquidity(TestConstants.USD_10_000_18DEC);
        _iporProtocol.miltonStorage.setJoseph(address(_iporProtocol.joseph));

        // when
        vm.prank(_liquidityProvider);
        vm.expectRevert("IPOR_300");
        _iporProtocol.joseph.itfRedeem(TestConstants.USD_1_000_18DEC, block.timestamp);
    }

    function testShouldNotRedeemIpTokensBecauseOfEmptyLiquidityPoolAfterRedeemLiquidity() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _cfg.josephImplementation = address(new MockCase1JosephDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        vm.prank(_liquidityProvider);
        _iporProtocol.joseph.itfProvideLiquidity(TestConstants.USD_10_000_18DEC, block.timestamp);

        // when
        vm.prank(_liquidityProvider);
        vm.expectRevert("IPOR_410");
        _iporProtocol.joseph.itfRedeem(TestConstants.USD_10_000_18DEC, block.timestamp);
    }

    function testShouldNotRedeemIpTokensBecauseRedeemAmountIsTooLow() public {
        // given
        _cfg.miltonImplementation = address(new MockCase0MiltonDai());
        _cfg.josephImplementation = address(new MockCase1JosephDai());
        _iporProtocol = _iporProtocolFactory.getDaiInstance(_cfg);

        // when
        vm.prank(_liquidityProvider);
        vm.expectRevert("IPOR_403");
        _iporProtocol.joseph.itfRedeem(TestConstants.ZERO, block.timestamp);
    }
}
