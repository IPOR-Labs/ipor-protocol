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

contract JosephProvideLiquidity is TestCommons, DataUtils, SwapUtils {
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

    function testShouldSetupInitValueForRedeemLPMaxUtilizationPercentage() public {
        // given
        address[] memory tokenAddresses = addressesToArray(
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken)
        );
        address[] memory ipTokenAddresses = addressesToArray(
            address(_ipTokenUsdt),
            address(_ipTokenUsdc),
            address(_ipTokenDai)
        );
        ItfIporOracle iporOracle = getIporOracleAssets(
            _userOne,
            tokenAddresses,
            uint32(block.timestamp),
            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT,
            0
        );
        address[] memory mockCase1StanleyAddresses = addressesToArray(
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken)
        );
        MiltonStorages memory miltonStorages = getMiltonStorages();
        address[] memory miltonStorageAddresses = addressesToArray(
            address(miltonStorages.miltonStorageUsdt),
            address(miltonStorages.miltonStorageUsdc),
            address(miltonStorages.miltonStorageDai)
        );
        MockCase0Miltons memory mockCase0Miltons = getMockCase0Miltons(
            address(iporOracle),
            address(_miltonSpreadModel),
            address(_usdtMockedToken),
            address(_usdcMockedToken),
            address(_daiMockedToken),
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        address[] memory mockCase0MiltonAddresses = addressesToArray(
            address(mockCase0Miltons.mockCase0MiltonUsdt),
            address(mockCase0Miltons.mockCase0MiltonUsdc),
            address(mockCase0Miltons.mockCase0MiltonDai)
        );
        MockCase0Josephs memory mockCase0Josephs = getMockCase0Josephs(
            tokenAddresses,
            ipTokenAddresses,
            mockCase0MiltonAddresses,
            miltonStorageAddresses,
            mockCase1StanleyAddresses
        );
        // when
        uint256 actualValueUsdt = mockCase0Josephs
            .mockCase0JosephUsdt
            .getRedeemLpMaxUtilizationRate();
        uint256 actualValueUsdc = mockCase0Josephs
            .mockCase0JosephUsdc
            .getRedeemLpMaxUtilizationRate();
        uint256 actualValueDai = mockCase0Josephs
            .mockCase0JosephDai
            .getRedeemLpMaxUtilizationRate();
        // then
        assertEq(actualValueUsdt, TestConstants.D18);
        assertEq(actualValueUsdc, TestConstants.D18);

        assertEq(actualValueDai, TestConstants.D18);
    }

    function testShouldProvideLiquidityAndTakeIpTokenWhemSimpleCase1And18Decimals() public {
        // given

        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        // when
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_14_000_18DEC, block.timestamp);
        IporTypes.MiltonBalancesMemory memory balance = mockCase0MiltonDai.getAccruedBalance();
        // then
        assertEq(TestConstants.USD_14_000_18DEC, _ipTokenDai.balanceOf(_liquidityProvider));
        assertEq(
            TestConstants.USD_14_000_18DEC,
            _daiMockedToken.balanceOf(address(mockCase0MiltonDai))
        );
        assertEq(TestConstants.USD_14_000_18DEC, balance.liquidityPool);
        assertEq(9986000 * TestConstants.D18, _daiMockedToken.balanceOf(_liquidityProvider));
    }

    function testShouldProvideLiquidityAndTakeIpTokenWhemSimpleCase1And6Decimals() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_usdtMockedToken),
            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
        );
        MockCase0Stanley stanleyUsdt = getMockCase0Stanley(address(_usdtMockedToken));
        MiltonStorage miltonStorageUsdt = getMiltonStorage();
        MockCase0MiltonUsdt mockCase0MiltonUsdt = getMockCase0MiltonUsdt(
            address(_usdtMockedToken),
            address(iporOracle),
            address(miltonStorageUsdt),
            address(_miltonSpreadModel),
            address(stanleyUsdt)
        );
        MockCase0JosephUsdt mockCase0JosephUsdt = getMockCase0JosephUsdt(
            address(_usdtMockedToken),
            address(_ipTokenUsdt),
            address(mockCase0MiltonUsdt),
            address(miltonStorageUsdt),
            address(stanleyUsdt)
        );
        prepareApproveForUsersUsd(
            _users,
            _usdtMockedToken,
            address(mockCase0JosephUsdt),
            address(mockCase0MiltonUsdt)
        );
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
        // when
        vm.prank(_liquidityProvider);
        mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_14_000_6DEC, block.timestamp);
        IporTypes.MiltonBalancesMemory memory balance = mockCase0MiltonUsdt.getAccruedBalance();
        // then
        assertEq(TestConstants.USD_14_000_18DEC, _ipTokenUsdt.balanceOf(_liquidityProvider));
        assertEq(
            TestConstants.USD_14_000_6DEC,
            _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt))
        );
        assertEq(TestConstants.USD_14_000_18DEC, balance.liquidityPool);
        assertEq(9986000000000, _usdtMockedToken.balanceOf(_liquidityProvider));
    }

    function testShouldNotProvideLiquidityWhenLiquidyPoolIsEmpty() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_10_000_18DEC, block.timestamp);
        //simulation that Liquidity Pool Balance equal 0, but ipToken is not burned
        miltonStorageDai.setJoseph(_userOne);
        vm.prank(_userOne);
        miltonStorageDai.subtractLiquidity(TestConstants.USD_10_000_18DEC);
        miltonStorageDai.setJoseph(address(mockCase0JosephDai));
        // when
        vm.prank(_liquidityProvider);
        vm.expectRevert("IPOR_300");
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_10_000_18DEC, block.timestamp);
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolBalanceExceeded() public {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.setMaxLiquidityPoolBalance(20000);
        mockCase0JosephDai.setMaxLpAccountContribution(15000);
        vm.prank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_15_000_18DEC, block.timestamp);
        // when other user provides liquidity
        vm.prank(_userOne);
        vm.expectRevert("IPOR_304");
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_15_000_18DEC, block.timestamp);
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolAccountContributionExceededCase1()
        public
    {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.setMaxLiquidityPoolBalance(2000000);
        mockCase0JosephDai.setMaxLpAccountContribution(50000);
        vm.startPrank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_10_000_18DEC, block.timestamp);
        // when
        vm.expectRevert("IPOR_305");
        mockCase0JosephDai.itfProvideLiquidity(51000 * TestConstants.D18, block.timestamp);
        vm.stopPrank();
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolAccountContributionExceededCase2()
        public
    {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.setMaxLiquidityPoolBalance(2000000);
        mockCase0JosephDai.setMaxLpAccountContribution(50000);
        vm.startPrank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_50_000_18DEC, block.timestamp);
        // when
        vm.expectRevert("IPOR_305");
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_50_000_18DEC, block.timestamp);
        vm.stopPrank();
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolAccountContributionExceededCase3()
        public
    {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.setMaxLiquidityPoolBalance(2000000);
        mockCase0JosephDai.setMaxLpAccountContribution(50000);
        vm.startPrank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_50_000_18DEC, block.timestamp);
        mockCase0JosephDai.itfRedeem(TestConstants.USD_50_000_18DEC, block.timestamp);
        // when
        vm.expectRevert("IPOR_305");
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_50_000_18DEC, block.timestamp);
        vm.stopPrank();
    }

    function testShouldNotProvideLiquidityWhenMaxLiquidityPoolAccountContributionExceededCase4()
        public
    {
        // given
        ItfIporOracle iporOracle = getIporOracleAsset(
            _userOne,
            address(_daiMockedToken),
            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT
        );
        MockCase0Stanley stanleyDai = getMockCase0Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase0MiltonDai mockCase0MiltonDai = getMockCase0MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase0MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(
            _users,
            _daiMockedToken,
            address(mockCase0JosephDai),
            address(mockCase0MiltonDai)
        );
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
        mockCase0JosephDai.setMaxLiquidityPoolBalance(2000000);
        mockCase0JosephDai.setMaxLpAccountContribution(50000);
        vm.startPrank(_liquidityProvider);
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_50_000_18DEC, block.timestamp);
        _ipTokenDai.transfer(_userThree, TestConstants.USD_50_000_18DEC);
        uint256 ipTokenLiquidityProviderBalance = _ipTokenDai.balanceOf(_liquidityProvider);
        assertEq(ipTokenLiquidityProviderBalance, TestConstants.ZERO);
        // when
        vm.expectRevert("IPOR_305");
        mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_50_000_18DEC, block.timestamp);
        vm.stopPrank();
    }
}
