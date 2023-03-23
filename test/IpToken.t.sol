// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./TestCommons.sol";
import "./utils/TestConstants.sol";
import "../contracts/libraries/Constants.sol";
import "../contracts/mocks/spread/MockSpreadModel.sol";
import "../contracts/tokens/IpToken.sol";
import "../contracts/mocks/tokens/MockTestnetToken.sol";
import "../../contracts/itf/ItfIporOracle.sol";
import "../../contracts/amm/MiltonStorage.sol";
import "../contracts/mocks/joseph/MockCase0JosephDai.sol";
import "../contracts/mocks/milton/MockCase0MiltonDai.sol";
import "../contracts/mocks/stanley/MockCase1Stanley.sol";
import {DataUtils} from "./utils/DataUtils.sol";

contract IpTokenTest is TestCommons, DataUtils {

	MockSpreadModel internal _miltonSpreadModel;
    IpToken internal _ipTokenDai;
    MockTestnetToken internal _daiMockedToken;

    function setUp() public {
        _miltonSpreadModel = prepareMockSpreadModel(
            TestConstants.ZERO,
            TestConstants.ZERO,
            TestConstants.ZERO_INT,
            TestConstants.ZERO_INT
        );
        _daiMockedToken = getTokenDai();
		_ipTokenDai = getIpTokenDai(address(_daiMockedToken));
		_admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
    }

    event Mint(address indexed account, uint256 amount);

	function testShouldTransferOwnershipWhenSimpleCase1() public {
		// given
		address expectedOwner = _userTwo;
		// when
		vm.prank(_admin);
		_ipTokenDai.transferOwnership(expectedOwner);
		vm.prank(_userTwo);
		_ipTokenDai.confirmTransferOwnership();
		// then
		vm.prank(_userOne);
		address actualOwner = _ipTokenDai.owner();
		assertEq(actualOwner, expectedOwner);
	}

	function testShouldNotTransferOwnershipWhenSenderNotCurrentOwner() public {
		// given
		address expectedOwner = _userTwo;
		// when
		vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
		vm.prank(_userThree);
		_ipTokenDai.transferOwnership(expectedOwner);
	}

	function testShouldNotConfirmTransferOwnershipWhenSenderNotCurrentOwner() public {
		// given
		address expectedOwner = _userTwo;
		// when
		vm.prank(_admin);
		_ipTokenDai.transferOwnership(expectedOwner);
		vm.expectRevert(abi.encodePacked("IPOR_007"));
		vm.prank(_userThree);
		_ipTokenDai.confirmTransferOwnership();
	}

	function testShouldNotConfirmTransferOwnershipTwiceWhenSenderNotAppointedOwner() public {
		// given
		address expectedOwner = _userTwo;
		// when
		vm.prank(_admin);
		_ipTokenDai.transferOwnership(expectedOwner);
		vm.prank(expectedOwner);
		_ipTokenDai.confirmTransferOwnership();
		vm.expectRevert(abi.encodePacked("IPOR_007"));
		vm.prank(expectedOwner);
		_ipTokenDai.confirmTransferOwnership();
	}

	function testShouldNotTransferOwnershipWhenSenderAlreadyLostOwnership() public {
		// given
		address expectedOwner = _userTwo;
		vm.prank(_admin);
		_ipTokenDai.transferOwnership(expectedOwner);
		vm.prank(expectedOwner);
		_ipTokenDai.confirmTransferOwnership();
		// when
		vm.expectRevert(abi.encodePacked("Ownable: caller is not the owner"));
		vm.prank(_admin);
		_ipTokenDai.transferOwnership(expectedOwner);
	}

	function testShouldHaveRightsToTransferOwnershipWhenSenderStillHasRights() public {
		// given
		address expectedOwner = _userTwo;
		vm.startPrank(_admin);
		_ipTokenDai.transferOwnership(expectedOwner);
		// when
		_ipTokenDai.transferOwnership(expectedOwner);
		vm.stopPrank();
		// then
		vm.prank(_userOne);
		address actualOwner = _ipTokenDai.owner();
		assertEq(actualOwner, _admin);
	}

	function testShouldNotMintIpTokenIfNotJoseph() public {
		// given
		// when
		vm.expectRevert(abi.encodePacked("IPOR_327"));
		vm.prank(_userTwo);
		_ipTokenDai.mint(_userOne, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC);
	}

	function testShouldNotMintIpTokenIfZero() public {
		// given
		_ipTokenDai.setJoseph(_admin);
		// when
		vm.expectRevert(abi.encodePacked("IPOR_400"));
		_ipTokenDai.mint(_userOne, TestConstants.ZERO);
	}

	function testShouldNotBurnIpTokenIfZero() public {
		// given
		_ipTokenDai.setJoseph(_admin);
		// when
		vm.expectRevert(abi.encodePacked("IPOR_401"));
		_ipTokenDai.burn(_userOne, TestConstants.ZERO);
	}

	function testShouldNotBurnIpTokenWhenNotJoseph() public {
		// given 
		// when
		vm.expectRevert(abi.encodePacked("IPOR_327"));
		vm.prank(_userTwo);
		_ipTokenDai.burn(_userOne, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC);
	}

	function testShouldEmitEvent() public {
		// given
		ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
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
		_ipTokenDai.setJoseph(_admin);
		// when
		vm.expectEmit(true, true, true, true);
		emit Mint(_userOne, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC);
		_ipTokenDai.mint(_userOne, TestConstants.TC_TOTAL_AMOUNT_10_000_18DEC);
		_ipTokenDai.setJoseph(address(mockCase0JosephDai));
	}

	function testShouldContain18Decimals() public {
		// given
		ItfIporOracle iporOracle =
            getIporOracleAsset(_userOne, address(_daiMockedToken), TestConstants.TC_DEFAULT_EMA_18DEC_64UINT);
        MockCase1Stanley stanleyDai = getMockCase1Stanley(address(_daiMockedToken));
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
		_ipTokenDai.setJoseph(_admin);
		uint256 expectedDecimals = 18;
		_ipTokenDai.setJoseph(_admin);
		// when
		uint256 actualDecimals = _ipTokenDai.decimals();
		// then
		assertEq(actualDecimals, expectedDecimals);
		_ipTokenDai.setJoseph(address(mockCase0JosephDai));
	}

	function testShouldContainCorrectUnderlyingTokenAddress() public {
		// given
		address expectedUnderlyingTokenAddress = address(_daiMockedToken);
		// when
		address actualUnderlyingTokenAddress = _ipTokenDai.getAsset();
		// then
		assertEq(actualUnderlyingTokenAddress, expectedUnderlyingTokenAddress);
	}

	function testShouldNotSendETHToIpTokenDAI() public payable {
		// given 
		// when
		vm.expectRevert(abi.encodePacked("Transaction reverted: function selector was not recognized and there's no fallback nor receive function"));
		address(_ipTokenDai).call{value: msg.value}("");
	}

}
