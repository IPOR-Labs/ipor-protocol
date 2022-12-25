// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {ProxyTester} from "foundry-upgrades/ProxyTester.sol";
import "../TestCommons.sol";
import "../../contracts/libraries/Constants.sol";
import "../../contracts/itf/ItfJosephDai.sol";
import "../../contracts/itf/ItfMiltonDai.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/DaiMockedToken.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/interfaces/types/MiltonTypes.sol";
import "../../contracts/interfaces/types/AmmTypes.sol";

contract MiltonEventsTest is Test, TestCommons {
    MockSpreadModel internal _miltonSpreadModel;
	ProxyTester internal _iporOracleProxy;
	ItfIporOracle internal _iporOracle;
	ProxyTester internal _miltonDaiProxy;
	ItfMiltonDai internal _miltonDai;
	ProxyTester internal _josephDaiProxy;
	ItfJosephDai internal _josephDai;
	ProxyTester internal _miltonStorageProxy;
	MiltonStorage internal _miltonStorage;
	address internal _admin;
	address internal _userOne;
	address internal _userTwo;
	address internal _userThree;
	address internal _liquidityProvider;

    /// @notice Emmited when trader opens new swap.
    event OpenSwap(
        /// @notice swap ID.
        uint256 indexed swapId,
        /// @notice trader that opened the swap
        address indexed buyer,
        /// @notice underlying asset
        address asset,
        /// @notice swap direction
        MiltonTypes.SwapDirection direction,
        /// @notice money structure related with this swap
        AmmTypes.OpenSwapMoney money,
        /// @notice the moment when swap was opened
        uint256 openTimestamp,
        /// @notice the moment when swap will achieve maturity
        uint256 endTimestamp,
        /// @notice attributes taken from IPOR Index indicators.
        MiltonTypes.IporSwapIndicator indicator
    );

    /// @notice Emmited when trader closes Swap.
    event CloseSwap(
        /// @notice swap ID.
        uint256 indexed swapId,
        /// @notice underlying asset
        address asset,
        /// @notice the moment when swap was closed
        uint256 closeTimestamp,
        /// @notice account that liquidated the swap
        address liquidator,
        /// @notice asset amount after closing swap that has been transferred from Milton to the Buyer. Value represented in 18 decimals.
        uint256 transferredToBuyer,
        /// @notice asset amount after closing swap that has been transferred from Milton to the Liquidator. Value represented in 18 decimals.
        uint256 transferredToLiquidator,
        /// @notice incomeFeeValue value transferred to treasury
        uint256 incomeFeeValue
    );

    function setUp() public {
        _miltonSpreadModel = new MockSpreadModel(0, 0, 0, 0);
		_iporOracleProxy = new ProxyTester();
		_iporOracle = new ItfIporOracle();
		_miltonDaiProxy = new ProxyTester();
		_miltonDai = new ItfMiltonDai();
		_josephDaiProxy = new ProxyTester();
		_josephDai = new ItfJosephDai();
		_miltonStorageProxy = new ProxyTester();
		_miltonStorage = new MiltonStorage();
		_admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
		_liquidityProvider = _getUserAddress(4);
		// set proxy type
		_iporOracleProxy.setType("uups");
		_miltonDaiProxy.setType("uups");
		_josephDaiProxy.setType("uups");
		_miltonStorageProxy.setType("uups");
    }

	function getIporOracle(address asset) public returns (ItfIporOracle) {
		address[] memory assets = new address[](1);
		assets[0] = asset;
		uint32[] memory updateTimestamps = new uint32[](1);
		updateTimestamps[0] = uint32(block.timestamp);
		uint64[] memory exponentialMovingAverages = new uint64[](1);
		exponentialMovingAverages[0] = 0;
		uint64[] memory exponentialWeightedMovingVariances = new uint64[](1);
		exponentialWeightedMovingVariances[0] = 0;
		address iporOracleProxyAddress = _iporOracleProxy.deploy(address(_iporOracle), _admin, abi.encodeWithSignature("initialize(address[],uint32[],uint64[],uint64[])", assets, updateTimestamps, exponentialMovingAverages, exponentialWeightedMovingVariances));
		ItfIporOracle iporOracle = ItfIporOracle(iporOracleProxyAddress);
		return iporOracle;
	}

	function getMiltonStorage() public returns (MiltonStorage) {
		address miltonStorageProxyAddress = _miltonStorageProxy.deploy(address(_miltonStorage), _admin, abi.encodeWithSignature("initialize()", ""));
		MiltonStorage miltonStorage = MiltonStorage(miltonStorageProxyAddress);
		return miltonStorage;
	}

	function getStanley(address asset) public returns (MockCase0Stanley) {
		MockCase0Stanley case0Stanley = new MockCase0Stanley(asset);
		return case0Stanley;
	}

	function getIpToken(address asset) public returns (IpToken) {
		IpToken ipToken = new IpToken("IP DAI", "ipDAI", asset);
		return ipToken;
	}
	
	function getMiltonDai(address asset, address iporOracleAddress, address miltonStorageAddress, address stanleyAddress) public returns (ItfMiltonDai) {
		address miltonDaiProxyAddress = _miltonDaiProxy.deploy(address(_miltonDai), _admin, abi.encodeWithSignature("initialize(bool,address,address,address,address,address)", false, asset, iporOracleAddress, miltonStorageAddress, address(_miltonSpreadModel), stanleyAddress));
		ItfMiltonDai miltonDai = ItfMiltonDai(miltonDaiProxyAddress);
		return miltonDai;
	}

	function getJosephDai(address asset, address ipToken, address miltonDaiAddress, address miltonStorageAddress, address stanleyAddress) public returns (ItfJosephDai) {
		address josephDaiProxyAddress = _josephDaiProxy.deploy(address(_josephDai), _admin, abi.encodeWithSignature("initialize(bool,address,address,address,address,address)", false, asset, ipToken, miltonDaiAddress, miltonStorageAddress, stanleyAddress));
		ItfJosephDai josephDai = ItfJosephDai(josephDaiProxyAddress);
		return josephDai;
	}

	function testShouldEmitEventWhenOpenPayFixedSwap18Decimals() public {
		// given
		_miltonSpreadModel.setCalculateQuotePayFixed(4 * 10**16);
		DaiMockedToken daiMockedToken = new DaiMockedToken(1*Constants.D18, 18);
		uint256 openTimestamp = 1671558470;
		uint256 endTimestamp = 1671840070;
		address[] memory users = new address[](5);
		users[0] = _admin;
		users[1] = _userOne;
		users[2] = _userTwo;
		users[3] = _userThree;
		users[4] = _liquidityProvider;
		MiltonStorage miltonStorageDai = getMiltonStorage();
		IpToken ipTokenDai = getIpToken(address(daiMockedToken));
		MockCase0Stanley stanleyDai = getStanley(address(daiMockedToken));
		ItfIporOracle iporOracle = getIporOracle(address(daiMockedToken)); 
		ItfMiltonDai miltonDai = getMiltonDai(address(daiMockedToken), address(iporOracle), address(miltonStorageDai), address(stanleyDai));
		ItfJosephDai josephDai = getJosephDai(address(daiMockedToken), address(ipTokenDai), address(miltonDai), address(miltonStorageDai), address(stanleyDai));
		// when
		for (uint256 i=0; i < users.length; ++i) {
			vm.prank(users[i]);
			daiMockedToken.approve(address(miltonDai), 1*10**16 * Constants.D18);
			vm.prank(users[i]);
			daiMockedToken.approve(address(josephDai), 1*10**16 * Constants.D18);	
			daiMockedToken.setupInitialAmount(address(users[i]), 1*10**7 * Constants.D18); // 10M
		}
		vm.prank(address(_iporOracleProxy));
		iporOracle.addUpdater(_userOne);
		vm.prank(_userOne);
		iporOracle.itfUpdateIndex(address(daiMockedToken), 3*10**16, openTimestamp); // random timestamp
		vm.prank(address(_josephDaiProxy));
		josephDai.setMaxLiquidityPoolBalance(10*10**6); // 10M
		vm.prank(address(_josephDaiProxy));
		josephDai.setMaxLpAccountContribution(1*10**6); // 1M
		vm.prank(address(_miltonStorageProxy));
		miltonStorageDai.setJoseph(address(josephDai));
		vm.prank(address(_miltonStorageProxy));
		miltonStorageDai.setMilton(address(miltonDai));
		ipTokenDai.setJoseph(address(josephDai));
		vm.prank(address(_miltonDaiProxy));
		miltonDai.setJoseph(address(josephDai));
		vm.prank(address(_miltonDaiProxy));
		miltonDai.setupMaxAllowanceForAsset(address(josephDai));
		vm.prank(address(_miltonDaiProxy));
		miltonDai.setupMaxAllowanceForAsset(address(stanleyDai));
		vm.prank(_liquidityProvider);
		josephDai.itfProvideLiquidity(28000*Constants.D18, openTimestamp);
		vm.prank(_userTwo);
		// vm.expectEmit(true, true, false, true);
		vm.expectEmit(true, true, false, false);
		emit OpenSwap(
			1, // swapId
			_userTwo, // buyer
			address(daiMockedToken), // asset
			MiltonTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING, // direction
			AmmTypes.OpenSwapMoney({
				totalAmount: 10000 * Constants.D18, // totalAmount
				collateral: 9967009897030890732780, // collateral
				notional: 99670098970308907327800, // notional
				openingFeeLPAmount: 2990102969109267220, // openingFeeLPAmount
				openingFeeTreasuryAmount: 0, // openingFeeTreasuryAmount
				iporPublicationFee: 10 * Constants.D18, // iporPublicationFee
				liquidationDepositAmount: 20 * Constants.D18 // liquidationDepositAmount
			}), // money
			openTimestamp, // openTimestamp
			endTimestamp, // endTimestamp
			MiltonTypes.IporSwapIndicator({
				iporIndexValue: 3 * 10**16, // iporIndexValue
				ibtPrice: 1 * Constants.D18, // ibtPrice
				ibtQuantity: 99670098970308907327800, // ibtQuantity
				fixedInterestRate: 4 * 10**16 // fixedInterestRate
			}) // indicator
		);
		miltonDai.itfOpenSwapPayFixed(
			openTimestamp, // openTimestamp
			10000 * Constants.D18, // totalAmount
			6*10**16, // acceptableFixedInterestRate
			10 * Constants.D18 // leverage
		);
		// when
		// then
		// assertEq(iporOracleProxyAddress, _iporOracleProxy.proxyAddress());
		// assertEq(iporOracleProxyAddress, address(_iporOracleProxy.uups()));
	}

}