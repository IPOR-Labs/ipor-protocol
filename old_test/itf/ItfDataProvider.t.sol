// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "../TestCommons.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import "../utils/TestConstants.sol";
import "contracts/mocks/spread/MockBaseAmmTreasurySpreadModelUsdc.sol";
import "contracts/amm/AmmStorage.sol";
import "contracts/interfaces/IIporRiskManagementOracle.sol";
import "contracts/itf/ItfIporOracle.sol";
import "contracts/itf/ItfDataProvider.sol";
import "contracts/itf/types/ItfDataProviderTypes.sol";
import "contracts/tokens/IpToken.sol";
import "contracts/mocks/tokens/MockTestnetToken.sol";
import "contracts/mocks/assetManagement/MockCaseBaseAssetManagement.sol";
import "contracts/mocks/ammTreasury/MockAmmTreasury.sol";

contract ItfDataProviderTest is TestCommons, DataUtils {
    MockBaseAmmTreasurySpreadModelUsdc internal _ammTreasurySpreadModel;
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    MockTestnetToken internal _daiMockedToken;
    IpToken internal _ipTokenUsdt;
    IpToken internal _ipTokenUsdc;
    IpToken internal _ipTokenDai;
    ItfDataProvider internal _itfDataProvider;
    ItfIporOracle internal _iporOracle;
    AmmStorage internal _ammStorage;
    MockAmmTreasury internal _ammTreasury;
    ItfJoseph internal _joseph;
    MockCaseBaseAssetManagement internal _assetManagement;
    IIporRiskManagementOracle internal _RiskManagementOracle;

    function getItfDataProvider(
        address[] memory tokenAddresses,
        address[] memory ammTreasuryAddresses,
        address[] memory ammStorageAddresses,
        address iporOracleAddress,
        address[] memory ammTreasurySpreadAddresses
    ) public returns (ItfDataProvider) {
        ItfDataProvider itfDataProviderImplementation = new ItfDataProvider();
        ERC1967Proxy itfDataProviderImplementationProxy = new ERC1967Proxy(
            address(itfDataProviderImplementation),
            abi.encodeWithSignature(
                "initialize(address[],address[],address[],address,address[])",
                tokenAddresses,
                ammTreasuryAddresses,
                ammStorageAddresses,
                iporOracleAddress,
                ammTreasurySpreadAddresses
            )
        );
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
        _iporOracle = getIporOracleAsset(_userOne, address(_usdcMockedToken));
        _RiskManagementOracle = getRiskManagementOracleAsset(
            _userOne,
            address(_usdcMockedToken),
            TestConstants.RMO_UTILIZATION_RATE_48_PER,
            TestConstants.RMO_UTILIZATION_RATE_80_PER,
            TestConstants.RMO_NOTIONAL_1B,
            TestConstants.RMO_SPREAD_0_1_PER
        );
        _ammStorage = getAmmStorage();
        _ammTreasurySpreadModel = new MockBaseAmmTreasurySpreadModelUsdc();
        _assetManagement = getMockCase1AssetManagement(address(_usdcMockedToken));
        _ammTreasury = getMockCase0AmmTreasuryUsdc(
            address(_usdcMockedToken),
            address(_iporOracle),
            address(_ammStorage),
            address(_ammTreasurySpreadModel),
            address(_assetManagement),
            address(_RiskManagementOracle)
        );
        _joseph = getMockCase0JosephUsdc(
            address(_usdcMockedToken),
            address(_ipTokenUsdc),
            address(_ammTreasury),
            address(_ammStorage),
            address(_assetManagement)
        );
    }

    function testShouldCollectDataFromIporOracleForItf() public {
        // given
        address[] memory tokenAddresses = new address[](1);
        tokenAddresses[0] = address(_usdcMockedToken);
        address iporOracleAddress = address(_iporOracle);
        address[] memory ammTreasuryAddresses = new address[](1);
        ammTreasuryAddresses[0] = address(_ammTreasury);
        address[] memory ammStorageAddresses = new address[](1);
        ammStorageAddresses[0] = address(_ammStorage);
        address[] memory ammTreasurySpreadAddresses = new address[](1);
        ammTreasurySpreadAddresses[0] = address(_ammTreasurySpreadModel);
        uint256 liquidityAmount = TestConstants.USD_10_000_6DEC;
        _itfDataProvider = getItfDataProvider(
            tokenAddresses,
            ammTreasuryAddresses,
            ammStorageAddresses,
            iporOracleAddress,
            ammTreasurySpreadAddresses
        );
        deal(address(_usdcMockedToken), _admin, liquidityAmount);
        prepareApproveForUsersUsd(_users, _usdcMockedToken, address(_joseph), address(_ammTreasury));
        prepareAmmTreasury(_ammTreasury, address(_joseph), address(_assetManagement));
        prepareJoseph(_joseph);
        prepareIpToken(_ipTokenUsdc, address(_joseph));
        _joseph.provideLiquidity(liquidityAmount);
        // when
        ItfDataProviderTypes.ItfIporOracleData memory iporOracleData = _itfDataProvider.getIporOracleData(
            block.timestamp,
            address(_usdcMockedToken)
        );
        ItfDataProviderTypes.ItfAmmTreasuryData memory ammTreasuryData = _itfDataProvider.getAmmTreasuryData(
            block.timestamp,
            address(_usdcMockedToken)
        );
        ItfDataProviderTypes.ItfAmmStorageData memory ammStorageData = _itfDataProvider.getAmmStorageData(
            address(_usdcMockedToken)
        );
        ItfDataProviderTypes.ItfAmmTreasurySpreadModelData memory ammTreasurySpreadModelData = _itfDataProvider
            .getAmmTreasurySpreadModelData(address(_usdcMockedToken));
        ItfDataProviderTypes.ItfAmmData memory ammData = _itfDataProvider.getAmmData(
            block.timestamp,
            address(_usdcMockedToken)
        );
        // then
        assertEq(iporOracleData.indexValue, TestConstants.ZERO);
        assertEq(iporOracleData.ibtPrice, TestConstants.D18);
        assertEq(iporOracleData.lastUpdateTimestamp, 1);
        assertEq(iporOracleData.accruedIndexValue, TestConstants.ZERO);
        assertEq(iporOracleData.accruedIbtPrice, TestConstants.D18);
        assertEq(iporOracleData.accruedExponentialMovingAverage, TestConstants.ZERO);
        assertEq(iporOracleData.accruedExponentialWeightedMovingVariance, TestConstants.ZERO);
        assertEq(ammTreasuryData.maxSwapCollateralAmount, 100000 * TestConstants.D18);
        assertEq(ammTreasuryData.maxLpUtilizationRate, 8 * TestConstants.D17);
        assertEq(ammTreasuryData.maxLpUtilizationRatePayFixed, 48 * TestConstants.D16);
        assertEq(ammTreasuryData.maxLpUtilizationRateReceiveFixed, 48 * TestConstants.D16);
        assertEq(ammTreasuryData.openingFeeRate, 300000000000000);
        assertEq(ammTreasuryData.openingFeeTreasuryPortionRate, TestConstants.ZERO);
        assertEq(ammTreasuryData.iporPublicationFee, TestConstants.TC_IPOR_PUBLICATION_AMOUNT_18DEC);
        assertEq(ammTreasuryData.liquidationDepositAmount, 20);
        assertEq(ammTreasuryData.wadLiquidationDepositAmount, TestConstants.TC_LIQUIDATION_DEPOSIT_AMOUNT_18DEC);
        assertEq(ammTreasuryData.maxLeveragePayFixed, TestConstants.LEVERAGE_1000_18DEC);
        assertEq(ammTreasuryData.maxLeverageReceiveFixed, TestConstants.LEVERAGE_1000_18DEC);
        assertEq(ammTreasuryData.minLeverage, TestConstants.LEVERAGE_18DEC);
        assertEq(ammTreasuryData.spreadPayFixed, 250000000000000);
        assertEq(ammTreasuryData.spreadReceiveFixed, -250000000201288);
        assertEq(ammTreasuryData.soapPayFixed, TestConstants.ZERO_INT);
        assertEq(ammTreasuryData.soapReceiveFixed, TestConstants.ZERO_INT);
        assertEq(ammTreasuryData.soap, TestConstants.ZERO_INT);
        assertEq(ammStorageData.totalCollateralPayFixed, TestConstants.ZERO);
        assertEq(ammStorageData.totalCollateralReceiveFixed, TestConstants.ZERO);
        assertEq(ammStorageData.liquidityPool, TestConstants.USD_10_000_18DEC);
        assertEq(ammStorageData.vault, TestConstants.ZERO);
        assertEq(ammStorageData.iporPublicationFee, TestConstants.ZERO);
        assertEq(ammStorageData.treasury, TestConstants.ZERO);
        assertEq(ammStorageData.totalNotionalPayFixed, TestConstants.ZERO);
        assertEq(ammStorageData.totalNotionalReceiveFixed, TestConstants.ZERO);
        assertEq(ammTreasurySpreadModelData.payFixedRegionOneBase, 246221635508210);
        assertEq(ammTreasurySpreadModelData.payFixedRegionOneSlopeForVolatility, 7175545968273476608);
        assertEq(ammTreasurySpreadModelData.payFixedRegionOneSlopeForMeanReversion, -998967008815501824);
        assertEq(ammTreasurySpreadModelData.payFixedRegionTwoBase, 250000000000000);
        assertEq(ammTreasurySpreadModelData.payFixedRegionTwoSlopeForVolatility, 600000002394766180352);
        assertEq(ammTreasurySpreadModelData.payFixedRegionTwoSlopeForMeanReversion, TestConstants.ZERO_INT);
        assertEq(ammTreasurySpreadModelData.receiveFixedRegionOneBase, -250000000201288);
        assertEq(ammTreasurySpreadModelData.receiveFixedRegionOneSlopeForVolatility, -2834673328995);
        assertEq(ammTreasurySpreadModelData.receiveFixedRegionOneSlopeForMeanReversion, 999999997304907264);
        assertEq(ammTreasurySpreadModelData.receiveFixedRegionTwoBase, -250000000000000);
        assertEq(ammTreasurySpreadModelData.receiveFixedRegionTwoSlopeForVolatility, -600000000289261748224);
        assertEq(ammTreasurySpreadModelData.receiveFixedRegionTwoSlopeForMeanReversion, TestConstants.ZERO_INT);
        assertEq(ammData.blockNumber, 1);
        assertEq(ammData.timestamp, 1);
        assertEq(ammData.asset, address(_usdcMockedToken));
    }
}
