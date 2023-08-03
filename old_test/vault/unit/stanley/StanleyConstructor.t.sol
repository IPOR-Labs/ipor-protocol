// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {TestCommons} from "../../../TestCommons.sol";
import {DataUtils} from "../../../utils/DataUtils.sol";
import {TestConstants} from "../../../utils/TestConstants.sol";
import {MockTestnetToken} from "@ipor-protocol/test/mocks/tokens/MockTestnetToken.sol";
import {AssetManagementDai} from "@ipor-protocol/contracts/vault/AssetManagementDai.sol";
import {AssetManagementUsdt} from "@ipor-protocol/contracts/vault/AssetManagementUsdt.sol";
import {AssetManagementUsdc} from "@ipor-protocol/contracts/vault/AssetManagementUsdc.sol";
import {IvToken} from "@ipor-protocol/contracts/tokens/IvToken.sol";
import {MockStrategy} from "@ipor-protocol/test/mocks/assetManagement/MockStrategy.sol";

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
        AssetManagementDai assetManagementDaiImpl = new AssetManagementDai();
        vm.expectRevert("IPOR_000");
        new ERC1967Proxy(
            address(assetManagementDaiImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(0),
                address(_ivTokenDai),
                address(_mockStrategyAave),
                address(_mockStrategyCompound)
            )
        );
    }

    function testShouldDeployNewIporVault() public {
        // given
        // when
        AssetManagementDai assetManagementDaiImpl = new AssetManagementDai();
        ERC1967Proxy assetManagementDaiProxy = new ERC1967Proxy(
            address(assetManagementDaiImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(_daiMockedToken),
                address(_ivTokenDai),
                address(_mockStrategyAave),
                address(_mockStrategyCompound)
            )
        );
        assertTrue(address(assetManagementDaiProxy) != address(0));
    }

    function testShouldThrowErrorWhenIvTokenAddressIsZero() public {
        // given
        // when
        AssetManagementDai assetManagementDaiImpl = new AssetManagementDai();
        vm.expectRevert("IPOR_000");
        new ERC1967Proxy(
            address(assetManagementDaiImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(_daiMockedToken),
                address(0),
                address(_mockStrategyAave),
                address(_mockStrategyCompound)
            )
        );
    }

    function testShouldThrowErrorWhenStrategyAaveAddressIsZero() public {
        // given
        // when
        AssetManagementDai assetManagementDaiImpl = new AssetManagementDai();
        vm.expectRevert("IPOR_000");
        new ERC1967Proxy(
            address(assetManagementDaiImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(_daiMockedToken),
                address(_ivTokenDai),
                address(0),
                address(_mockStrategyCompound)
            )
        );
    }

    function testShouldThrowErrorWhenStrategyCompoundAddressIsZero() public {
        // given
        // when
        AssetManagementDai assetManagementDaiImpl = new AssetManagementDai();
        vm.expectRevert("IPOR_000");
        new ERC1967Proxy(
            address(assetManagementDaiImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(_daiMockedToken),
                address(_ivTokenDai),
                address(_mockStrategyAave),
                address(0)
            )
        );
    }

    function testShouldThrowErrorWhenStrategyAaveAssetIsNotEqualToIporVaultAsset() public {
        // given
        _mockStrategyAave.setAsset(address(_usdtMockedToken));
        // when
        AssetManagementDai assetManagementDaiImpl = new AssetManagementDai();
        vm.expectRevert("IPOR_500");
        new ERC1967Proxy(
            address(assetManagementDaiImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(_daiMockedToken),
                address(_ivTokenDai),
                address(_mockStrategyAave),
                address(_mockStrategyCompound)
            )
        );
    }

    function testShouldThrowErrorWhenStrategyCompoundAssetIsNotEqualToIporVaultAsset() public {
        // given
        _mockStrategyCompound.setAsset(address(_usdtMockedToken));
        // when
        AssetManagementDai assetManagementDaiImpl = new AssetManagementDai();
        vm.expectRevert("IPOR_500");
        new ERC1967Proxy(
            address(assetManagementDaiImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(_daiMockedToken),
                address(_ivTokenDai),
                address(_mockStrategyAave),
                address(_mockStrategyCompound)
            )
        );
    }

    function testShouldThrowErrorWhenAssetManagementAssetIsNotEqualToIvTokenAsset() public {
        // given
        // when
        AssetManagementDai assetManagementDaiImpl = new AssetManagementDai();
        vm.expectRevert("IPOR_001");
        new ERC1967Proxy(
            address(assetManagementDaiImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(_usdtMockedToken),
                address(_ivTokenDai),
                address(_mockStrategyAave),
                address(_mockStrategyCompound)
            )
        );
    }

    function testShouldBeAbleToPauseContractWhenSenderIsOwner() public {
        // given
        AssetManagementDai assetManagementDaiImpl = new AssetManagementDai();
        ERC1967Proxy assetManagementDaiProxy = new ERC1967Proxy(
            address(assetManagementDaiImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(_daiMockedToken),
                address(_ivTokenDai),
                address(_mockStrategyAave),
                address(_mockStrategyCompound)
            )
        );
        AssetManagementDai assetManagementDai = AssetManagementDai(address(assetManagementDaiProxy));
        assetManagementDai.addPauseGuardian(address(this));

        // when
        assetManagementDai.pause();
        // then
        assertTrue(assetManagementDai.paused());
    }

    function testShouldBeAbleToUnpauseContractWhenSenderIsOwner() public {
        // given
        AssetManagementDai assetManagementDaiImpl = new AssetManagementDai();
        ERC1967Proxy assetManagementDaiProxy = new ERC1967Proxy(
            address(assetManagementDaiImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(_daiMockedToken),
                address(_ivTokenDai),
                address(_mockStrategyAave),
                address(_mockStrategyCompound)
            )
        );
        AssetManagementDai assetManagementDai = AssetManagementDai(address(assetManagementDaiProxy));
        assetManagementDai.addPauseGuardian(address(this));
        assetManagementDai.pause();
        assertTrue(assetManagementDai.paused());
        // when
        assetManagementDai.unpause();
        // then
        assertFalse(assetManagementDai.paused());
    }

    function testShouldNotBeAbleToUnpauseContractWhenSenderIsNotOwner() public {
        // given
        AssetManagementDai assetManagementDaiImpl = new AssetManagementDai();
        ERC1967Proxy assetManagementDaiProxy = new ERC1967Proxy(
            address(assetManagementDaiImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(_daiMockedToken),
                address(_ivTokenDai),
                address(_mockStrategyAave),
                address(_mockStrategyCompound)
            )
        );
        AssetManagementDai assetManagementDai = AssetManagementDai(address(assetManagementDaiProxy));
        assetManagementDai.addPauseGuardian(address(this));
        assetManagementDai.pause();
        assertTrue(assetManagementDai.paused());
        // when
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(_userOne);
        assetManagementDai.unpause();
        // then
        assertTrue(assetManagementDai.paused());
    }

    function testShouldNotBeAbleToPauseContractWhenSenderIsNotOwner() public {
        // given
        AssetManagementDai assetManagementDaiImpl = new AssetManagementDai();
        ERC1967Proxy assetManagementDaiProxy = new ERC1967Proxy(
            address(assetManagementDaiImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(_daiMockedToken),
                address(_ivTokenDai),
                address(_mockStrategyAave),
                address(_mockStrategyCompound)
            )
        );
        AssetManagementDai assetManagementDai = AssetManagementDai(address(assetManagementDaiProxy));
        // when
        vm.expectRevert("IPOR_011");
        vm.prank(_userOne);
        assetManagementDai.pause();
        // then
        assertFalse(assetManagementDai.paused());
    }

    function testShouldNotPauseSmartContractSpecificMethodsWhenPaused() public {
        // given
        AssetManagementDai assetManagementDaiImpl = new AssetManagementDai();
        ERC1967Proxy assetManagementDaiProxy = new ERC1967Proxy(
            address(assetManagementDaiImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(_daiMockedToken),
                address(_ivTokenDai),
                address(_mockStrategyAave),
                address(_mockStrategyCompound)
            )
        );
        AssetManagementDai assetManagementDai = AssetManagementDai(address(assetManagementDaiProxy));
        assetManagementDai.addPauseGuardian(address(this));
        // when
        assetManagementDai.pause();
        // then
        assetManagementDai.totalBalance(_userOne);
    }

    function testShouldPauseSmartContractSpecificMethods() public {
        // given
        AssetManagementDai assetManagementDaiImpl = new AssetManagementDai();
        ERC1967Proxy assetManagementDaiProxy = new ERC1967Proxy(
            address(assetManagementDaiImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(_daiMockedToken),
                address(_ivTokenDai),
                address(_mockStrategyAave),
                address(_mockStrategyCompound)
            )
        );
        AssetManagementDai assetManagementDai = AssetManagementDai(address(assetManagementDaiProxy));
        assetManagementDai.addPauseGuardian(address(this));
        // when
        assetManagementDai.pause();
        // then
        vm.expectRevert("Pausable: paused");
        assetManagementDai.deposit(100);
        vm.expectRevert("Pausable: paused");
        assetManagementDai.withdraw(100);
        vm.expectRevert("Pausable: paused");
        assetManagementDai.withdrawAll();
        vm.expectRevert("Pausable: paused");
        assetManagementDai.migrateAssetToStrategyWithMaxApy();
        vm.expectRevert("Pausable: paused");
        assetManagementDai.setStrategyAave(address(_mockStrategyAave));
        vm.expectRevert("Pausable: paused");
        assetManagementDai.setStrategyCompound(address(_mockStrategyCompound));
        vm.expectRevert("Pausable: paused");
        assetManagementDai.setAmmTreasury(_userOne);
    }

    function testShouldReturnVersionOfContract() public {
        // given
        AssetManagementDai assetManagementDaiImpl = new AssetManagementDai();
        ERC1967Proxy assetManagementDaiProxy = new ERC1967Proxy(
            address(assetManagementDaiImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(_daiMockedToken),
                address(_ivTokenDai),
                address(_mockStrategyAave),
                address(_mockStrategyCompound)
            )
        );
        AssetManagementDai assetManagementDai = AssetManagementDai(address(assetManagementDaiProxy));
        // when
        uint256 version = assetManagementDai.getVersion();
        // then
        assertEq(version, 2);
    }

    function testShouldReturnProperAsset() public {
        // given
        AssetManagementDai assetManagementDaiImpl = new AssetManagementDai();
        ERC1967Proxy assetManagementDaiProxy = new ERC1967Proxy(
            address(assetManagementDaiImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(_daiMockedToken),
                address(_ivTokenDai),
                address(_mockStrategyAave),
                address(_mockStrategyCompound)
            )
        );
        AssetManagementDai assetManagementDai = AssetManagementDai(address(assetManagementDaiProxy));
        // when
        address asset = assetManagementDai.getAsset();
        // then
        assertEq(asset, address(_daiMockedToken));
    }

    function testShouldDeployNewAssetManagementUsdt() public {
        // given
        IvToken _ivTokenUsdt = new IvToken("IvToken", "IVT", address(_usdtMockedToken));
        MockStrategy _mockStrategyAaveUsdt = new MockStrategy();
        MockStrategy _mockStrategyCompoundUsdt = new MockStrategy();
        _mockStrategyAaveUsdt.setShareToken(address(_usdtMockedToken));
        _mockStrategyCompoundUsdt.setShareToken(address(_usdtMockedToken));
        _mockStrategyAaveUsdt.setAsset(address(_usdtMockedToken));
        _mockStrategyCompoundUsdt.setAsset(address(_usdtMockedToken));
        // when
        AssetManagementUsdt assetManagementUsdtImpl = new AssetManagementUsdt();
        ERC1967Proxy assetManagementUsdtProxy = new ERC1967Proxy(
            address(assetManagementUsdtImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(_usdtMockedToken),
                address(_ivTokenUsdt),
                address(_mockStrategyAaveUsdt),
                address(_mockStrategyCompoundUsdt)
            )
        );
        AssetManagementUsdt assetManagementUsdt = AssetManagementUsdt(address(assetManagementUsdtProxy));
        // then
        assertTrue(address(assetManagementUsdt) != address(0));
        assertEq(assetManagementUsdt.getAsset(), address(_usdtMockedToken));
    }

    function testShouldDeployNewAssetManagementUsdc() public {
        // given
        IvToken _ivTokenUsdc = new IvToken("IvToken", "IVT", address(_usdcMockedToken));
        MockStrategy _mockStrategyAaveUsdc = new MockStrategy();
        MockStrategy _mockStrategyCompoundUsdc = new MockStrategy();
        _mockStrategyAaveUsdc.setShareToken(address(_usdcMockedToken));
        _mockStrategyCompoundUsdc.setShareToken(address(_usdcMockedToken));
        _mockStrategyAaveUsdc.setAsset(address(_usdcMockedToken));
        _mockStrategyCompoundUsdc.setAsset(address(_usdcMockedToken));
        // when
        AssetManagementUsdc assetManagementUsdcImpl = new AssetManagementUsdc();
        ERC1967Proxy assetManagementUsdcProxy = new ERC1967Proxy(
            address(assetManagementUsdcImpl),
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                address(_usdcMockedToken),
                address(_ivTokenUsdc),
                address(_mockStrategyAaveUsdc),
                address(_mockStrategyCompoundUsdc)
            )
        );
        AssetManagementUsdc assetManagementUsdc = AssetManagementUsdc(address(assetManagementUsdcProxy));
        // then
        assertTrue(address(assetManagementUsdc) != address(0));
        assertEq(assetManagementUsdc.getAsset(), address(_usdcMockedToken));
    }
}
