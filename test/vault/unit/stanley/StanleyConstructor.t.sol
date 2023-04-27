// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {TestCommons} from "../../../TestCommons.sol";
import {DataUtils} from "../../../utils/DataUtils.sol";
import {TestConstants} from "../../../utils/TestConstants.sol";
import {MockTestnetToken} from "../../../../contracts/mocks/tokens/MockTestnetToken.sol";
import {StanleyDai} from "../../../../contracts/vault/StanleyDai.sol";
import {StanleyUsdt} from "../../../../contracts/vault/StanleyUsdt.sol";
import {StanleyUsdc} from "../../../../contracts/vault/StanleyUsdc.sol";
import {IvToken} from "../../../../contracts/tokens/IvToken.sol";
import {MockStrategy} from "../../../../contracts/mocks/stanley/MockStrategy.sol";

contract IporLogicTest is TestCommons, DataUtils {
    MockTestnetToken internal _daiMockedToken;
    MockTestnetToken internal _usdtMockedToken;
    MockTestnetToken internal _usdcMockedToken;
    IvToken internal _ivTokenDai;
    MockStrategy internal _mockStrategyAave;
    MockStrategy internal _mockStrategyCompound;

    function setupStrategiesDai() public {
        _mockStrategyAave.setShareToken(address(_daiMockedToken));
        _mockStrategyCompound.setShareToken(address(_daiMockedToken));
        _mockStrategyAave.setAsset(address(_daiMockedToken));
        _mockStrategyCompound.setAsset(address(_daiMockedToken));
    }

    function setUp() public {
        _daiMockedToken = getTokenDai();
        _usdtMockedToken = getTokenUsdt();
        _usdcMockedToken = getTokenUsdc();
        _ivTokenDai = new IvToken("IvToken", "IVT", address(_daiMockedToken));
        _mockStrategyAave = new MockStrategy();
        _mockStrategyCompound = new MockStrategy();
        _admin = address(this);
        _userOne = _getUserAddress(1);
        _userTwo = _getUserAddress(2);
        _userThree = _getUserAddress(3);
        _liquidityProvider = _getUserAddress(4);
        _users = usersToArray(_admin, _userOne, _userTwo, _userThree, _liquidityProvider);
        setupStrategiesDai();
    }

    function testShouldThrowErrorWhenUnderlyingTokenAddressIsZero() public {
        // given
        // when
        StanleyDai stanleyDaiImpl = new StanleyDai();
        vm.expectRevert("IPOR_000");
        ERC1967Proxy stanleyDaiProxy = new ERC1967Proxy(
    address(stanleyDaiImpl),
    abi.encodeWithSignature("initialize(address,address,address,address)", address(0), address(_ivTokenDai), address(_mockStrategyAave), address(_mockStrategyCompound))
    );
        StanleyDai stanleyDai = StanleyDai(address(stanleyDaiProxy));
    }

    function testShouldDeployNewIporVault() public {
        // given
        // when
        StanleyDai stanleyDaiImpl = new StanleyDai();
        ERC1967Proxy stanleyDaiProxy = new ERC1967Proxy(
    address(stanleyDaiImpl),
    abi.encodeWithSignature("initialize(address,address,address,address)", address(_daiMockedToken), address(_ivTokenDai), address(_mockStrategyAave), address(_mockStrategyCompound))
    );
        assertTrue(address(stanleyDaiProxy) != address(0));
    }

    function testShouldThrowErrorWhenIvTokenAddressIsZero() public {
        // given
        // when
        StanleyDai stanleyDaiImpl = new StanleyDai();
        vm.expectRevert("IPOR_000");
        ERC1967Proxy stanleyDaiProxy = new ERC1967Proxy(
    address(stanleyDaiImpl),
    abi.encodeWithSignature("initialize(address,address,address,address)", address(_daiMockedToken), address(0), address(_mockStrategyAave), address(_mockStrategyCompound))
    );
    }

    function testShouldThrowErrorWhenStrategyAaveAddressIsZero() public {
        // given
        // when
        StanleyDai stanleyDaiImpl = new StanleyDai();
        vm.expectRevert("IPOR_000");
        ERC1967Proxy stanleyDaiProxy = new ERC1967Proxy(
    address(stanleyDaiImpl),
    abi.encodeWithSignature("initialize(address,address,address,address)", address(_daiMockedToken), address(_ivTokenDai), address(0), address(_mockStrategyCompound))
    );
    }

    function testShouldThrowErrorWhenStrategyCompoundAddressIsZero() public {
        // given
        // when
        StanleyDai stanleyDaiImpl = new StanleyDai();
        vm.expectRevert("IPOR_000");
        ERC1967Proxy stanleyDaiProxy = new ERC1967Proxy(
    address(stanleyDaiImpl),
    abi.encodeWithSignature("initialize(address,address,address,address)", address(_daiMockedToken), address(_ivTokenDai), address(_mockStrategyAave), address(0))
    );
    }

    function testShouldThrowErrorWhenStrategyAaveAssetIsNotEqualToIporVaultAsset() public {
        // given
        _mockStrategyAave.setAsset(address(_usdtMockedToken));
        // when
        StanleyDai stanleyDaiImpl = new StanleyDai();
        vm.expectRevert("IPOR_500");
        ERC1967Proxy stanleyDaiProxy = new ERC1967Proxy(
    address(stanleyDaiImpl),
    abi.encodeWithSignature("initialize(address,address,address,address)", address(_daiMockedToken), address(_ivTokenDai), address(_mockStrategyAave), address(_mockStrategyCompound))
    );
    }

    function testShouldThrowErrorWhenStrategyCompoundAssetIsNotEqualToIporVaultAsset() public {
        // given
        _mockStrategyCompound.setAsset(address(_usdtMockedToken));
        // when
        StanleyDai stanleyDaiImpl = new StanleyDai();
        vm.expectRevert("IPOR_500");
        ERC1967Proxy stanleyDaiProxy = new ERC1967Proxy(
    address(stanleyDaiImpl),
    abi.encodeWithSignature("initialize(address,address,address,address)", address(_daiMockedToken), address(_ivTokenDai), address(_mockStrategyAave), address(_mockStrategyCompound))
    );
    }

    function testShouldThrowErrorWhenStanleyAssetIsNotEqualToIvTokenAsset() public {
        // given
        // when
        StanleyDai stanleyDaiImpl = new StanleyDai();
        vm.expectRevert("IPOR_001");
        ERC1967Proxy stanleyDaiProxy = new ERC1967Proxy(
    address(stanleyDaiImpl),
    abi.encodeWithSignature("initialize(address,address,address,address)", address(_usdtMockedToken), address(_ivTokenDai), address(_mockStrategyAave), address(_mockStrategyCompound))
    );
    }

    function testShouldBeAbleToPauseContractWhenSenderIsOwner() public {
        // given
        StanleyDai stanleyDaiImpl = new StanleyDai();
        ERC1967Proxy stanleyDaiProxy = new ERC1967Proxy(
    address(stanleyDaiImpl),
    abi.encodeWithSignature("initialize(address,address,address,address)", address(_daiMockedToken), address(_ivTokenDai), address(_mockStrategyAave), address(_mockStrategyCompound))
    );
        StanleyDai stanleyDai = StanleyDai(address(stanleyDaiProxy));
        stanleyDai.addGuardian(address(this));

        // when
        stanleyDai.pause();
        // then
        assertTrue(stanleyDai.paused());
    }

    function testShouldBeAbleToUnpauseContractWhenSenderIsOwner() public {
        // given
        StanleyDai stanleyDaiImpl = new StanleyDai();
        ERC1967Proxy stanleyDaiProxy = new ERC1967Proxy(
    address(stanleyDaiImpl),
    abi.encodeWithSignature("initialize(address,address,address,address)", address(_daiMockedToken), address(_ivTokenDai), address(_mockStrategyAave), address(_mockStrategyCompound))
    );
        StanleyDai stanleyDai = StanleyDai(address(stanleyDaiProxy));
        stanleyDai.addGuardian(address(this));
        stanleyDai.pause();
        assertTrue(stanleyDai.paused());
        // when
        stanleyDai.unpause();
        // then
        assertFalse(stanleyDai.paused());
    }

    function testShouldNotBeAbleToUnpauseContractWhenSenderIsNotOwner() public {
        // given
        StanleyDai stanleyDaiImpl = new StanleyDai();
        ERC1967Proxy stanleyDaiProxy = new ERC1967Proxy(
    address(stanleyDaiImpl),
    abi.encodeWithSignature("initialize(address,address,address,address)", address(_daiMockedToken), address(_ivTokenDai), address(_mockStrategyAave), address(_mockStrategyCompound))
    );
        StanleyDai stanleyDai = StanleyDai(address(stanleyDaiProxy));
        stanleyDai.addGuardian(address(this));
        stanleyDai.pause();
        assertTrue(stanleyDai.paused());
        // when
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userOne);
        stanleyDai.unpause();
        // then
        assertTrue(stanleyDai.paused());
    }

    function testShouldNotBeAbleToPauseContractWhenSenderIsNotOwner() public {
        // given
        StanleyDai stanleyDaiImpl = new StanleyDai();
        ERC1967Proxy stanleyDaiProxy = new ERC1967Proxy(
    address(stanleyDaiImpl),
    abi.encodeWithSignature("initialize(address,address,address,address)", address(_daiMockedToken), address(_ivTokenDai), address(_mockStrategyAave), address(_mockStrategyCompound))
    );
        StanleyDai stanleyDai = StanleyDai(address(stanleyDaiProxy));
        // when
        vm.expectRevert("IPOR_011");
        vm.prank(_userOne);
        stanleyDai.pause();
        // then
        assertFalse(stanleyDai.paused());
    }

    function testShouldNotPauseSmartContractSpecificMethodsWhenPaused() public {
        // given
        StanleyDai stanleyDaiImpl = new StanleyDai();
        ERC1967Proxy stanleyDaiProxy = new ERC1967Proxy(
    address(stanleyDaiImpl),
    abi.encodeWithSignature("initialize(address,address,address,address)", address(_daiMockedToken), address(_ivTokenDai), address(_mockStrategyAave), address(_mockStrategyCompound))
    );
        StanleyDai stanleyDai = StanleyDai(address(stanleyDaiProxy));
        stanleyDai.addGuardian(address(this));
        // when
        stanleyDai.pause();
        // then
        stanleyDai.totalBalance(_userOne);
    }

    function testShouldPauseSmartContractSpecificMethods() public {
        // given
        StanleyDai stanleyDaiImpl = new StanleyDai();
        ERC1967Proxy stanleyDaiProxy = new ERC1967Proxy(
    address(stanleyDaiImpl),
    abi.encodeWithSignature("initialize(address,address,address,address)", address(_daiMockedToken), address(_ivTokenDai), address(_mockStrategyAave), address(_mockStrategyCompound))
    );
        StanleyDai stanleyDai = StanleyDai(address(stanleyDaiProxy));
        stanleyDai.addGuardian(address(this));
        // when
        stanleyDai.pause();
        // then
        vm.expectRevert("Pausable: paused");
        stanleyDai.deposit(100);
        vm.expectRevert("Pausable: paused");
        stanleyDai.withdraw(100);
        vm.expectRevert("Pausable: paused");
        stanleyDai.withdrawAll();
        vm.expectRevert("Pausable: paused");
        stanleyDai.migrateAssetToStrategyWithMaxApr();
        vm.expectRevert("Pausable: paused");
        stanleyDai.setStrategyAave(address(_mockStrategyAave));
        vm.expectRevert("Pausable: paused");
        stanleyDai.setStrategyCompound(address(_mockStrategyCompound));
        vm.expectRevert("Pausable: paused");
        stanleyDai.setMilton(_userOne);
    }

    function testShouldReturnVersionOfContract() public {
        // given
        StanleyDai stanleyDaiImpl = new StanleyDai();
        ERC1967Proxy stanleyDaiProxy = new ERC1967Proxy(
    address(stanleyDaiImpl),
    abi.encodeWithSignature("initialize(address,address,address,address)", address(_daiMockedToken), address(_ivTokenDai), address(_mockStrategyAave), address(_mockStrategyCompound))
    );
        StanleyDai stanleyDai = StanleyDai(address(stanleyDaiProxy));
        // when
        uint256 version = stanleyDai.getVersion();
        // then
        assertEq(version, 2);
    }

    function testShouldReturnProperAsset() public {
        // given
        StanleyDai stanleyDaiImpl = new StanleyDai();
        ERC1967Proxy stanleyDaiProxy = new ERC1967Proxy(
    address(stanleyDaiImpl),
    abi.encodeWithSignature("initialize(address,address,address,address)", address(_daiMockedToken), address(_ivTokenDai), address(_mockStrategyAave), address(_mockStrategyCompound))
    );
        StanleyDai stanleyDai = StanleyDai(address(stanleyDaiProxy));
        // when
        address asset = stanleyDai.getAsset();
        // then
        assertEq(asset, address(_daiMockedToken));
    }

    function testShouldDeployNewStanleyUsdt() public {
        // given
        IvToken _ivTokenUsdt = new IvToken("IvToken", "IVT", address(_usdtMockedToken));
        MockStrategy _mockStrategyAaveUsdt = new MockStrategy();
        MockStrategy _mockStrategyCompoundUsdt = new MockStrategy();
        _mockStrategyAaveUsdt.setShareToken(address(_usdtMockedToken));
        _mockStrategyCompoundUsdt.setShareToken(address(_usdtMockedToken));
        _mockStrategyAaveUsdt.setAsset(address(_usdtMockedToken));
        _mockStrategyCompoundUsdt.setAsset(address(_usdtMockedToken));
        // when
        StanleyUsdt stanleyUsdtImpl = new StanleyUsdt();
        ERC1967Proxy stanleyUsdtProxy = new ERC1967Proxy(
    address(stanleyUsdtImpl),
    abi.encodeWithSignature("initialize(address,address,address,address)", address(_usdtMockedToken), address(_ivTokenUsdt), address(_mockStrategyAaveUsdt), address(_mockStrategyCompoundUsdt))
    );
        StanleyUsdt stanleyUsdt = StanleyUsdt(address(stanleyUsdtProxy));
        // then
        assertTrue(address(stanleyUsdt) != address(0));
        assertEq(stanleyUsdt.getAsset(), address(_usdtMockedToken));
    }

    function testShouldDeployNewStanleyUsdc() public {
        // given
        IvToken _ivTokenUsdc = new IvToken("IvToken", "IVT", address(_usdcMockedToken));
        MockStrategy _mockStrategyAaveUsdc = new MockStrategy();
        MockStrategy _mockStrategyCompoundUsdc = new MockStrategy();
        _mockStrategyAaveUsdc.setShareToken(address(_usdcMockedToken));
        _mockStrategyCompoundUsdc.setShareToken(address(_usdcMockedToken));
        _mockStrategyAaveUsdc.setAsset(address(_usdcMockedToken));
        _mockStrategyCompoundUsdc.setAsset(address(_usdcMockedToken));
        // when
        StanleyUsdc stanleyUsdcImpl = new StanleyUsdc();
        ERC1967Proxy stanleyUsdcProxy = new ERC1967Proxy(
    address(stanleyUsdcImpl),
    abi.encodeWithSignature("initialize(address,address,address,address)", address(_usdcMockedToken), address(_ivTokenUsdc), address(_mockStrategyAaveUsdc), address(_mockStrategyCompoundUsdc))
    );
        StanleyUsdc stanleyUsdc = StanleyUsdc(address(stanleyUsdcProxy));
        // then
        assertTrue(address(stanleyUsdc) != address(0));
        assertEq(stanleyUsdc.getAsset(), address(_usdcMockedToken));
    }
}
