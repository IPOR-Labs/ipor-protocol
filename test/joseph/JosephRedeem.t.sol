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
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/interfaces/types/IporTypes.sol";

contract JosephRedeem is TestCommons, DataUtils, SwapUtils {
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
            TestConstants.PERCENTAGE_4_18DEC, TestConstants.PERCENTAGE_2_18DEC, TestConstants.ZERO_INT, TestConstants.ZERO_INT
        );
    }

    function testShouldRedeemIpToken18DecimalsSimpleCase1() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
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
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase0MiltonDai));
        prepareMilton(mockCase0MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
		uint256 redeemFee = 50 * TestConstants.D18;
		vm.startPrank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(TestConstants.USD_14_000_18DEC, block.timestamp);
        // when
		mockCase0JosephDai.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
		vm.stopPrank();
		IporTypes.MiltonBalancesMemory memory balance = mockCase0MiltonDai.getAccruedBalance();
        // then
		assertEq(4000 * TestConstants.D18, _ipTokenDai.balanceOf(_liquidityProvider));
		assertEq(4000 * TestConstants.D18 + redeemFee, _daiMockedToken.balanceOf(address(mockCase0MiltonDai)));
		assertEq(4000 * TestConstants.D18 + redeemFee, balance.liquidityPool);
		assertEq(9996000 * TestConstants.D18 - redeemFee, _daiMockedToken.balanceOf(_liquidityProvider));
    }

    function testShouldRedeemIpToken6DecimalsSimpleCase1() public {
        // given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_usdtMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
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
        prepareApproveForUsersDai(_users, _usdtMockedToken, address(mockCase0JosephUsdt), address(mockCase0MiltonUsdt));
        prepareMilton(mockCase0MiltonUsdt, address(mockCase0JosephUsdt), address(stanleyUsdt));
        prepareJoseph(mockCase0JosephUsdt);
        prepareIpToken(_ipTokenUsdt, address(mockCase0JosephUsdt));
		uint256 redeemFee18Dec = 50 * TestConstants.D18;
		uint256 redeemFee6Dec = 50 * TestConstants.N1__0_6DEC;
		vm.startPrank(_liquidityProvider);
		mockCase0JosephUsdt.itfProvideLiquidity(TestConstants.USD_14_000_6DEC, block.timestamp);
        // when
		mockCase0JosephUsdt.itfRedeem(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
		vm.stopPrank();
		 IporTypes.MiltonBalancesMemory memory balance = mockCase0MiltonUsdt.getAccruedBalance();
        // then
		assertEq(4000 * TestConstants.D18, _ipTokenUsdt.balanceOf(_liquidityProvider));
		assertEq(4000 * TestConstants.N1__0_6DEC + redeemFee6Dec, _usdtMockedToken.balanceOf(address(mockCase0MiltonUsdt)));
		assertEq(4000 * TestConstants.D18 + redeemFee18Dec, balance.liquidityPool);
		assertEq(9996000 * TestConstants.N1__0_6DEC - redeemFee6Dec, _usdtMockedToken.balanceOf(_liquidityProvider));
    }

}