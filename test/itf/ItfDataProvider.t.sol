// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import "../utils/TestConstants.sol";
import "../utils/TestConstants.sol";
import "../../contracts/mocks/spread/MockBaseMiltonSpreadModelUsdc.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/interfaces/IIporRiskManagementOracle.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/itf/ItfDataProvider.sol";
import "../../contracts/itf/types/ItfDataProviderTypes.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
import "../../contracts/mocks/milton/MockCase0MiltonUsdc.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdc.sol";

contract ItfDataProviderTest is TestCommons, DataUtils {
    MockBaseMiltonSpreadModelUsdc internal _miltonSpreadModel;
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockTestnetToken internal _daiMockedToken;
    IpToken internal _ipTokenUsdt;
    IpToken internal _ipTokenUsdc;
    IpToken internal _ipTokenDai;
	ItfDataProvider internal _itfDataProvider;
	ItfIporOracle internal _iporOracle;
	MiltonStorage internal _miltonStorage;
	MockCase0MiltonUsdc internal _milton;
	MockCase0JosephUsdc internal _joseph;
	MockCase1Stanley internal _stanley;
	IIporRiskManagementOracle internal _RiskManagementOracle;

    function getItfDataProvider(
		address[] memory tokenAddresses,
		address[] memory miltonAddresses,
		address[] memory miltonStorageAddresses,
		address iporOracleAddress,
		address[] memory miltonSpreadAddresses
	) public returns (ItfDataProvider) {
        ItfDataProvider itfDataProviderImplementation = new ItfDataProvider();
        ERC1967Proxy itfDataProviderImplementationProxy = new ERC1967Proxy(address(itfDataProviderImplementation), abi.encodeWithSignature("initialize(address[],address[],address[],address,address[])", tokenAddresses, miltonAddresses, miltonStorageAddresses, iporOracleAddress, miltonSpreadAddresses));
		return ItfDataProvider(address(itfDataProviderImplementationProxy));
    }

	function setUp() public {
        _usdcMockedToken = getTokenUsdc();
        _ipTokenUsdc = getIpTokenUsdc(address(_usdcMockedToken));
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
		_iporOracle = getIporOracleAsset(_userOne, address(_usdcMockedToken), TestConstants.TC_5_EMA_18DEC_64UINT);
		_RiskManagementOracle = getRiskManagementOracleAsset(
			_userOne,
			address(_usdcMockedToken),
			TestConstants.RMO_UTILIZATION_RATE_48_PER,
			TestConstants.RMO_UTILIZATION_RATE_80_PER,
			TestConstants.RMO_NOTIONAL_1B
		);
		_miltonStorage = getMiltonStorage();
		_miltonSpreadModel = new MockBaseMiltonSpreadModelUsdc();
		_stanley = getMockCase1Stanley(address(_usdcMockedToken));
		_milton = getMockCase0MiltonUsdc(
            address(_usdcMockedToken),
            address(_iporOracle),
            address(_miltonStorage),
            address(_miltonSpreadModel),
            address(_stanley),
            address(_RiskManagementOracle)
        );
		_joseph = getMockCase0JosephUsdc(
			address(_usdcMockedToken),
            address(_ipTokenUsdc),
            address(_milton),
            address(_miltonStorage),
            address(_stanley)
		);
	}

	function testShouldCollectDataFromIporOracleForItf() public {
		// given
		address[] memory tokenAddresses = new address[](1);
		tokenAddresses[0] = address(_usdcMockedToken);
		address iporOracleAddress = address(_iporOracle);
		address[] memory miltonAddresses = new address[](1);
		miltonAddresses[0] = address(_milton);
		address[] memory miltonStorageAddresses = new address[](1);
		miltonStorageAddresses[0] = address(_miltonStorage);
		address[] memory miltonSpreadAddresses = new address[](1);
		miltonSpreadAddresses[0] = address(_miltonSpreadModel);
		uint256 liquidityAmount = TestConstants.USD_10_000_6DEC;
		_itfDataProvider = getItfDataProvider(
			tokenAddresses,
			miltonAddresses,
			miltonStorageAddresses,
			iporOracleAddress,
			miltonSpreadAddresses
		);
        deal(address(_usdcMockedToken), _admin, liquidityAmount);
        prepareApproveForUsersUsd(_users, _usdcMockedToken, address(_joseph), address(_milton));
        prepareMilton(_milton, address(_joseph), address(_stanley));
        prepareJoseph(_joseph);
        prepareIpToken(_ipTokenUsdc, address(_joseph));
		_joseph.provideLiquidity(liquidityAmount);
		// when
		ItfDataProviderTypes.ItfIporOracleData memory iporOracleData = _itfDataProvider.getIporOracleData(block.timestamp, address(_usdcMockedToken));
		ItfDataProviderTypes.ItfMiltonData memory miltonData = _itfDataProvider.getMiltonData(block.timestamp, address(_usdcMockedToken));
		ItfDataProviderTypes.ItfMiltonStorageData memory miltonStorageData = _itfDataProvider.getMiltonStorageData(address(_usdcMockedToken));
		ItfDataProviderTypes.ItfMiltonSpreadModelData memory miltonSpreadModelData = _itfDataProvider.getMiltonSpreadModelData(address(_usdcMockedToken));
		ItfDataProviderTypes.ItfAmmData memory ammData = _itfDataProvider.getAmmData(block.timestamp, address(_usdcMockedToken));
		// then
		assertEq(iporOracleData.decayFactorValue, 999997217008929160);
		assertEq(iporOracleData.indexValue, TestConstants.ZERO);
		assertEq(iporOracleData.ibtPrice, TestConstants.D18);
		assertEq(iporOracleData.exponentialMovingAverage, TestConstants.TC_5_EMA_18DEC_64UINT);
		assertEq(iporOracleData.exponentialWeightedMovingVariance, TestConstants.ZERO);
		assertEq(iporOracleData.lastUpdateTimestamp, 1);
		assertEq(iporOracleData.accruedIndexValue, TestConstants.ZERO);
		assertEq(iporOracleData.accruedIbtPrice, TestConstants.D18);
		assertEq(iporOracleData.accruedExponentialMovingAverage, TestConstants.TC_5_EMA_18DEC_64UINT);
		assertEq(iporOracleData.accruedExponentialWeightedMovingVariance, TestConstants.ZERO);
		assertEq(miltonData.maxSwapCollateralAmount, 100000 * TestConstants.D18);
		assertEq(miltonData.maxLpUtilizationRate, 8 * TestConstants.D17);
		assertEq(miltonData.maxLpUtilizationRatePayFixed, 48 * TestConstants.D16);
		assertEq(miltonData.maxLpUtilizationRateReceiveFixed, 48 * TestConstants.D16);
		assertEq(miltonData.openingFeeRate, 300000000000000);
		assertEq(miltonData.openingFeeTreasuryPortionRate, TestConstants.ZERO);
		assertEq(miltonData.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
		assertEq(miltonData.liquidationDepositAmount, 20);
		assertEq(miltonData.wadLiquidationDepositAmount, TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC);
		assertEq(miltonData.maxLeveragePayFixed, TestConstants.LEVERAGE_1000_18DEC);
		assertEq(miltonData.maxLeverageReceiveFixed, TestConstants.LEVERAGE_1000_18DEC);
		assertEq(miltonData.minLeverage, TestConstants.LEVERAGE_18DEC);
		assertEq(miltonData.spreadPayFixed, 50194572076283301);
		assertEq(miltonData.spreadReceiveFixed, -50249999865446651);
		assertEq(miltonData.soapPayFixed, TestConstants.ZERO_INT);
		assertEq(miltonData.soapReceiveFixed, TestConstants.ZERO_INT);
		assertEq(miltonData.soap, TestConstants.ZERO_INT);
		assertEq(miltonStorageData.totalCollateralPayFixed, TestConstants.ZERO);
		assertEq(miltonStorageData.totalCollateralReceiveFixed, TestConstants.ZERO);
		assertEq(miltonStorageData.liquidityPool, TestConstants.USD_10_000_18DEC);
		assertEq(miltonStorageData.vault, TestConstants.ZERO);
		assertEq(miltonStorageData.iporPublicationFee, TestConstants.ZERO);
		assertEq(miltonStorageData.treasury, TestConstants.ZERO);
		assertEq(miltonStorageData.totalNotionalPayFixed, TestConstants.ZERO);
		assertEq(miltonStorageData.totalNotionalReceiveFixed, TestConstants.ZERO);
		assertEq(miltonSpreadModelData.payFixedRegionOneBase, 246221635508210);
		assertEq(miltonSpreadModelData.payFixedRegionOneSlopeForVolatility, 7175545968273476608);
		assertEq(miltonSpreadModelData.payFixedRegionOneSlopeForMeanReversion, -998967008815501824);
		assertEq(miltonSpreadModelData.payFixedRegionTwoBase, 250000000000000);
		assertEq(miltonSpreadModelData.payFixedRegionTwoSlopeForVolatility, 600000002394766180352);
		assertEq(miltonSpreadModelData.payFixedRegionTwoSlopeForMeanReversion, TestConstants.ZERO_INT);
		assertEq(miltonSpreadModelData.receiveFixedRegionOneBase, -250000000201288);
		assertEq(miltonSpreadModelData.receiveFixedRegionOneSlopeForVolatility, -2834673328995);
		assertEq(miltonSpreadModelData.receiveFixedRegionOneSlopeForMeanReversion, 999999997304907264);
		assertEq(miltonSpreadModelData.receiveFixedRegionTwoBase, -250000000000000);
		assertEq(miltonSpreadModelData.receiveFixedRegionTwoSlopeForVolatility, -600000000289261748224);
		assertEq(miltonSpreadModelData.receiveFixedRegionTwoSlopeForMeanReversion, TestConstants.ZERO_INT);
		assertEq(ammData.blockNumber, 1);
		assertEq(ammData.timestamp, 1);
		assertEq(ammData.asset, address(_usdcMockedToken));
	}
}
