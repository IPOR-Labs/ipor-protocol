// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../TestCommons.sol";
import {DataUtils} from "../utils/DataUtils.sol";
import {SwapUtils} from "../utils/SwapUtils.sol";
import "../utils/TestConstants.sol";
import "../../contracts/mocks/spread/MockSpreadModel.sol";
import "../../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/tokens/IpToken.sol";
import "../../contracts/mocks/milton/MockCase1MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../../contracts/mocks/milton/MockCase1MiltonUsdt.sol";
import "../../contracts/mocks/milton/MockCase0MiltonUsdt.sol";
import "../../contracts/mocks/stanley/MockCase1Stanley.sol";
import "../../contracts/mocks/stanley/MockCase0Stanley.sol";
import "../../contracts/mocks/stanley/aave/TestERC20.sol";
import "../../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../../contracts/mocks/joseph/MockCase0JosephUsdt.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../../contracts/amm/pool/JosephDai.sol";
import "../../contracts/amm/pool/JosephUsdt.sol";
import "../../contracts/amm/pool/JosephUsdc.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/interfaces/types/IporTypes.sol";

contract JosephExchangeRateLiquidity is TestCommons, DataUtils, SwapUtils {
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
            TestConstants.ZERO, TestConstants.ZERO, TestConstants.ZERO_INT, TestConstants.ZERO_INT
        );
    }

	function testShouldPauseSmartContractWhenSenderIsAnAdmin() public {
		// given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase1MiltonDai mockCase1MiltonDai = getMockCase1MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase1MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase1MiltonDai));
        prepareMilton(mockCase1MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
		// when
		vm.prank(_admin);
		mockCase0JosephDai.pause();
		// then
		vm.prank(_userOne);
		vm.expectRevert("Pausable: paused");
		mockCase0JosephDai.provideLiquidity(123);
	}

	function testShouldPauseSmartContractSpecificMethods() public {
		// given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase1MiltonDai mockCase1MiltonDai = getMockCase1MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase1MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase1MiltonDai));
        prepareMilton(mockCase1MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
		// when
		vm.startPrank(_admin);
		mockCase0JosephDai.pause();
		// then
		vm.expectRevert("Pausable: paused");
		mockCase0JosephDai.rebalance();
		vm.expectRevert("Pausable: paused");
		mockCase0JosephDai.depositToStanley(123);
		vm.expectRevert("Pausable: paused");
		mockCase0JosephDai.withdrawFromStanley(123);
		vm.expectRevert("Pausable: paused");
		mockCase0JosephDai.withdrawAllFromStanley();
		vm.expectRevert("Pausable: paused");
		mockCase0JosephDai.setCharlieTreasury(_userTwo);
		vm.expectRevert("Pausable: paused");
		mockCase0JosephDai.setTreasury(_userTwo);
		vm.expectRevert("Pausable: paused");
		mockCase0JosephDai.setCharlieTreasuryManager(_userTwo);
		vm.expectRevert("Pausable: paused");
		mockCase0JosephDai.setTreasuryManager(_userTwo);
		vm.stopPrank();
		vm.startPrank(_userOne);
		vm.expectRevert("Pausable: paused");
		mockCase0JosephDai.provideLiquidity(123);
		vm.expectRevert("Pausable: paused");
		mockCase0JosephDai.redeem(123);
		vm.expectRevert("Pausable: paused");
		mockCase0JosephDai.transferToTreasury(123);
		vm.expectRevert("Pausable: paused");
		mockCase0JosephDai.transferToCharlieTreasury(123);
		vm.stopPrank();
	}

	function testShouldNotPauseSmartContractSpecificMethodsWhenPaused() public {
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
		vm.prank(_liquidityProvider);
		mockCase0JosephDai.itfProvideLiquidity(TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC, block.timestamp);
		// when
		vm.prank(_admin);
		mockCase0JosephDai.pause();
		// then
		vm.startPrank(_userOne);
		mockCase0JosephDai.getVersion();
		mockCase0JosephDai.getCharlieTreasury();
		mockCase0JosephDai.getTreasury();
		mockCase0JosephDai.getCharlieTreasuryManager();
		mockCase0JosephDai.getTreasuryManager();
		mockCase0JosephDai.getRedeemLpMaxUtilizationRate();
		mockCase0JosephDai.getMiltonStanleyBalanceRatio();
		mockCase0JosephDai.getAsset();
		mockCase0JosephDai.calculateExchangeRate();
		vm.stopPrank();
	}

	function testShouldNotPauseSmartContractWhenSenderIsNotAdmin() public {
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
		// when
		vm.prank(_userThree);
		vm.expectRevert("Ownable: caller is not the owner");
		mockCase0JosephDai.pause();
	}

	function testShouldUnpauseSmartContractWhenSenderIsAdmin() public {
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
		vm.prank(_admin);
		mockCase0JosephDai.pause();
		vm.prank(_userOne);
		vm.expectRevert("Pausable: paused");
		mockCase0JosephDai.provideLiquidity(123);
		// when
		vm.prank(_admin);
		mockCase0JosephDai.unpause();
		vm.prank(_userOne);
		mockCase0JosephDai.provideLiquidity(123);
		// then
		assertEq(_ipTokenDai.balanceOf(_userOne), 123);
	}

	function testShouldNotUnPauseSmartContractWhenSenderIsNotAdmin() public {
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
		vm.prank(_admin);
		mockCase0JosephDai.unpause();
		// when
		vm.prank(_userThree);
		vm.expectRevert("Ownable: caller is not the owner");
		mockCase0JosephDai.unpause();
	}

	function testShouldTransferOwnershipWhenSimpleCase1() public {
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
		// when
		vm.prank(_admin);
		mockCase0JosephDai.transferOwnership(_userTwo);
		vm.prank(_userTwo);
		mockCase0JosephDai.confirmTransferOwnership();
		// then
		vm.prank(_userOne);
		assertEq(mockCase0JosephDai.owner(), _userTwo);
	}

	function testShouldNotTransferOwnershipWhenSenderIsNotCurrentOwner() public {
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
		// when
		vm.prank(_userThree);
		vm.expectRevert("Ownable: caller is not the owner");
		mockCase0JosephDai.transferOwnership(_userTwo);
	}

	function testShouldNotConfirmTransferOwnershipWhenSenderIsNotAppointedOwner() public {
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
		// when
		vm.prank(_admin);
		mockCase0JosephDai.transferOwnership(_userTwo);
		// then
		vm.prank(_userThree);
		vm.expectRevert("IPOR_007");
		mockCase0JosephDai.confirmTransferOwnership();
	}

	function testShouldNotConfirmTransferOwnershipTwiceWhenSenderIsNotAppointedOwner() public {
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
		// when
		vm.prank(_admin);
		mockCase0JosephDai.transferOwnership(_userTwo);
		vm.prank(_userTwo);
		mockCase0JosephDai.confirmTransferOwnership();
		// then
		vm.prank(_userTwo);
		vm.expectRevert("IPOR_007");
		mockCase0JosephDai.confirmTransferOwnership();
	}

	function testShouldNotTransferOwnershipWhenSenderAlreadyLostOwnership() public {
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
		vm.prank(_admin);
		mockCase0JosephDai.transferOwnership(_userTwo);
		vm.prank(_userTwo);
		mockCase0JosephDai.confirmTransferOwnership();
		// when
		vm.prank(_admin);
		vm.expectRevert("Ownable: caller is not the owner");
		mockCase0JosephDai.transferOwnership(_userTwo);
	}

	function testShouldHaveRightsToTransferOwnershipWhenSenderStillHasRights() public {
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
		vm.startPrank(_admin);
		mockCase0JosephDai.transferOwnership(_userTwo);
		// when
		mockCase0JosephDai.transferOwnership(_userTwo);
		vm.stopPrank();
		// then
		vm.prank(_userOne);
		assertEq(mockCase0JosephDai.owner(), _admin);
	}

	function testShouldNotSendETHToJosephDAIUSDCUSDT() public payable {
		// given
		address[] memory tokenAddresses =
            addressesToArray(address(_usdtMockedToken), address(_usdcMockedToken), address(_daiMockedToken));
		address[] memory ipTokenAddresses =
            addressesToArray(address(_ipTokenUsdt), address(_ipTokenUsdc), address(_ipTokenDai));
        ItfIporOracle iporOracle = getIporOracleAssets(
            _userOne,
            tokenAddresses,
            uint32(block.timestamp),
            TestConstants.TC_DEFAULT_EMA_18DEC_64UINT,
            TestConstants.ZERO_64UINT
        );
        address[] memory mockCase0StanleyAddresses = addressesToArray(
            address(getMockCase0Stanley(address(_usdtMockedToken))),
            address(getMockCase0Stanley(address(_usdcMockedToken))),
            address(getMockCase0Stanley(address(_daiMockedToken)))
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
            mockCase0StanleyAddresses
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
			mockCase0StanleyAddresses 
        );
        // when
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(mockCase0Josephs.mockCase0JosephUsdt).call{value: msg.value}("");
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(mockCase0Josephs.mockCase0JosephUsdc).call{value: msg.value}("");
        vm.expectRevert(
            "Transaction reverted: function selector was not recognized and there's no fallback nor receive function"
        );
        address(mockCase0Josephs.mockCase0JosephDai).call{value: msg.value}("");	
	}

	function testShouldDeployJosephDai() public {
		// given 
		JosephDai josephDaiImplementation = new JosephDai();
		ERC1967Proxy josephDaiProxy = new ERC1967Proxy(address(josephDaiImplementation), abi.encodeWithSignature("initialize(bool,address,address,address,address,address)", false, address(_daiMockedToken), address(_ipTokenDai), address(_daiMockedToken), address(_daiMockedToken), address(_daiMockedToken)));	
		JosephDai josephDai = JosephDai(address(josephDaiProxy));
		// when
		address josephDaiAddress = josephDai.getAsset();
		// then
		assertEq(josephDaiAddress, address(_daiMockedToken));
	}

	function testShouldDeployJosephUsdc() public {
		// given 
		JosephUsdc josephUsdcImplementation = new JosephUsdc();
		ERC1967Proxy josephUsdcProxy = new ERC1967Proxy(address(josephUsdcImplementation), abi.encodeWithSignature("initialize(bool,address,address,address,address,address)", false, address(_usdcMockedToken), address(_ipTokenUsdc), address(_usdcMockedToken), address(_usdcMockedToken), address(_usdcMockedToken)));	
		JosephUsdc josephUsdc = JosephUsdc(address(josephUsdcProxy));
		// when
		address josephUsdcAddress = josephUsdc.getAsset();
		// then
		assertEq(josephUsdcAddress, address(_usdcMockedToken));
	}

	function testShouldDeployJosephUsdt() public {
		// given 
		JosephUsdt josephUsdtImplementation = new JosephUsdt();
		ERC1967Proxy josephUsdtProxy = new ERC1967Proxy(address(josephUsdtImplementation), abi.encodeWithSignature("initialize(bool,address,address,address,address,address)", false, address(_usdtMockedToken), address(_ipTokenUsdt), address(_usdtMockedToken), address(_usdtMockedToken), address(_usdtMockedToken)));	
		JosephUsdt josephUsdt = JosephUsdt(address(josephUsdtProxy));
		// when
		address josephUsdtAddress = josephUsdt.getAsset();
		// then
		assertEq(josephUsdtAddress, address(_usdtMockedToken));
	}

	function testShouldReturnDefaultMiltonStanleyBalanceRatio() public {
		// given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase1MiltonDai mockCase1MiltonDai = getMockCase1MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase1MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase1MiltonDai));
        prepareMilton(mockCase1MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
		// when
		vm.prank(_admin);
		uint256 ratio = mockCase0JosephDai.getMiltonStanleyBalanceRatio();
		// then
		assertEq(ratio, 85 * TestConstants.D16);
	}

	function testShouldChangeMiltonStanleyBalanceRatio() public {
		// given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase1MiltonDai mockCase1MiltonDai = getMockCase1MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase1MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase1MiltonDai));
        prepareMilton(mockCase1MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
		// when
		vm.startPrank(_admin);
		mockCase0JosephDai.setMiltonStanleyBalanceRatio(TestConstants.PERCENTAGE_50_18DEC);
		// then
		vm.stopPrank();
		uint256 ratio = mockCase0JosephDai.getMiltonStanleyBalanceRatio();
		assertEq(ratio, TestConstants.PERCENTAGE_50_18DEC);
	}

	function testShouldNotChangeMiltonStanleyBalanceRatioWhenNewRatioIsZero() public {
		// given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase1MiltonDai mockCase1MiltonDai = getMockCase1MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase1MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase1MiltonDai));
        prepareMilton(mockCase1MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
		// when
		vm.prank(_admin);
		vm.expectRevert("IPOR_409");
		mockCase0JosephDai.setMiltonStanleyBalanceRatio(TestConstants.ZERO);
	}

	function testShouldNotChangeMiltonStanleyBalanceRatioWhenNewRatioIsGreaterThanOne() public {
		// given
        ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
        MiltonStorage miltonStorageDai = getMiltonStorage();
        MockCase1MiltonDai mockCase1MiltonDai = getMockCase1MiltonDai(
            address(_daiMockedToken),
            address(iporOracle),
            address(miltonStorageDai),
            address(_miltonSpreadModel),
            address(stanleyDai)
        );
        MockCase0JosephDai mockCase0JosephDai = getMockCase0JosephDai(
            address(_daiMockedToken),
            address(_ipTokenDai),
            address(mockCase1MiltonDai),
            address(miltonStorageDai),
            address(stanleyDai)
        );
        prepareApproveForUsersDai(_users, _daiMockedToken, address(mockCase0JosephDai), address(mockCase1MiltonDai));
        prepareMilton(mockCase1MiltonDai, address(mockCase0JosephDai), address(stanleyDai));
        prepareJoseph(mockCase0JosephDai);
        prepareIpToken(_ipTokenDai, address(mockCase0JosephDai));
		// when
		vm.prank(_admin);
		vm.expectRevert("IPOR_409");
		mockCase0JosephDai.setMiltonStanleyBalanceRatio(TestConstants.D18);
	}
}
