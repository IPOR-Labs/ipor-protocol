// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/itf/ItfIporOracle.sol";

contract ItfIporOracleTest is TestCommons, DataUtils {

	MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockTestnetToken internal _daiMockedToken;
    MockSpreadModel internal _miltonSpreadModel;
	ItfIporOracle internal _iporOracle;
	address[] internal _assets;

	function setUp() public {
		_daiMockedToken = getTokenDai();
		_usdtMockedToken = getTokenUsdt();
		_usdcMockedToken = getTokenUsdc();
		_assets = [address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken)];
		_miltonSpreadModel = prepareMockSpreadModel(
            TestConstants.ZERO,
            TestConstants.ZERO,
            TestConstants.ZERO_INT,
            TestConstants.ZERO_INT
        );
        _userOne = _getUserAddress(1);
		_iporOracle = getIporOracleAssets(_userOne, _assets, uint32(block.timestamp), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT, TestConstants.ZERO_64UINT);
	}

	function testShouldSetNewAbsoluteValueForDecayFactor() public {
		// given
		uint256 timestamp = 2225022130;
		uint256 decayFactorBefore = _iporOracle.itfGetDecayFactorValue(timestamp);
		// when
		_iporOracle.setDecayFactor(TestConstants.D16);
		// then
		uint256 decayFactorAfter = _iporOracle.itfGetDecayFactorValue(timestamp);
		assertEq(decayFactorBefore, TestConstants.ZERO);
		assertEq(decayFactorAfter, TestConstants.D16);
	}

}