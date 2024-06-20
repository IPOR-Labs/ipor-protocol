// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../../contracts/oracles/IporOracle.sol";
import "../../../contracts/chains/arbitrum/router/IporProtocolRouterArbitrum.sol";
import "../../../contracts/interfaces/IAmmSwapsLens.sol";
import "../../../contracts/interfaces/IAmmOpenSwapLens.sol";
import "../../../contracts/interfaces/IAmmCloseSwapLens.sol";
import "../../../contracts/chains/ethereum/amm-commons/AmmSwapsLens.sol";
import "../../../contracts/amm/AmmPoolsLens.sol";
import "../../../contracts/amm/AssetManagementLens.sol";
import "../../../contracts/chains/arbitrum/amm-wstEth/AmmOpenSwapServiceWstEth.sol";
import "../../../contracts/chains/arbitrum/amm-wstEth/AmmCloseSwapServiceWstEth.sol";
import "../../../contracts/amm/AmmPoolsService.sol";
import "../../../contracts/chains/arbitrum/amm-commons/AmmCloseSwapLensArbitrum.sol";
import "../../../contracts/chains/arbitrum/amm-commons/AmmGovernanceServiceArbitrum.sol";
import "../../../contracts/chains/arbitrum/amm-commons/AmmSwapsLensArbitrum.sol";

import "../../../contracts/chains/arbitrum/amm-wstEth/AmmPoolsServiceWstEth.sol";
import "../../../contracts/base/amm/AmmStorageBaseV1.sol";
import "../../../contracts/base/amm/AmmTreasuryBaseV2.sol";
import "../../../contracts/base/spread/SpreadBaseV1.sol";

import "../../../contracts/tokens/IpToken.sol";
import "../../arbitrum/interfaces/IERC20Bridged.sol";
import {AmmPoolsLensArbitrum} from "../../../contracts/chains/arbitrum/amm-commons/AmmPoolsLensArbitrum.sol";
import {AmmPoolsServiceUsdc} from "../../../contracts/chains/arbitrum/amm-usdc/AmmPoolsServiceUsdc.sol";
import {IAmmPoolsServiceUsdc} from "../../../contracts/chains/arbitrum/interfaces/IAmmPoolsServiceUsdc.sol";
import {AmmOpenSwapServiceUsdc} from "../../../contracts/chains/arbitrum/amm-usdc/AmmOpenSwapServiceUsdc.sol";
import {AmmCloseSwapServiceUsdc} from "../../../contracts/chains/arbitrum/amm-usdc/AmmCloseSwapServiceUsdc.sol";
import "../../../contracts/amm-usdm/AmmPoolsServiceUsdm.sol";
import {MockPlasmaVault} from "../../mocks/tokens/MockPlasmaVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract UsdcTestForkCommonArbitrum is Test {
    uint256 public constant PROTOCOL_DECIMALS = 1e18;
    address public constant PROTOCOL_OWNER = 0xD92E9F039E4189c342b4067CC61f5d063960D248;

    address internal constant WST_ETH_BRIDGE = 0x07D4692291B9E30E326fd31706f686f83f331B82;
    address constant USDM_MINT_ROLE = 0x48AEB395FB0E4ff8433e9f2fa6E0579838d33B62;

    address private _defaultAddress = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;

    address public treasurer = _getUserAddress(555);

    address public constant IPOR = 0x34229B3f16fBCDfA8d8d9d17C0852F9496f4C7BB;
    address public constant wstETH = 0x5979D7b546E38E414F7E9822514be443A4800529;
    address public constant USDM = 0x59D9356E565Ab3A36dD77763Fc0d87fEaf85508C;

    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    address public iporOracleImpl = 0x4d05f3d755f7996df0EF9c89Baeb328990068Ee5;
    address public iporOracleProxy = 0x70DdDE503edf4816B5991Ca5E2f9DE79e295F2D0;

    address public iporProtocolRouterImpl = 0xC9357414F910247bF3E0540ecaA8C641960Cdc03;
    address public iporProtocolRouterProxy = 0x760Fa0aB719c4067D3A8d4727Cf07E8f3Bf118db;

    uint256 public messageSignerPrivateKey;
    address public messageSignerAddress;

    address public ammSwapsLens;
    address public ammPoolsLens;
    address public ammCloseSwapLens;
    address public ammGovernanceService;

    address public ipUsdc;
    address public ammTreasuryUsdcImpl;
    address public ammTreasuryUsdcProxy;
    address public ammStorageUsdcImpl;
    address public ammStorageUsdcProxy;
    address public ammAssetManagementUsdc;


    address public spreadUsdc;
    address public ammPoolsServiceUsdc;
    address public ammOpenSwapServiceUsdc;
    address public ammCloseSwapServiceUsdc;


    function _init() internal {
        messageSignerPrivateKey = 0x12341234;
        messageSignerAddress = vm.addr(messageSignerPrivateKey);

        vm.createSelectFork(vm.envString("ARBITRUM_PROVIDER_URL"), 211080762);

        vm.startPrank(PROTOCOL_OWNER);

        _createAmmAssetManagement();

        _createDummyContracts();
        _createIpToken();
        _createAmmStorage();
        _upgradeAmmTreasury();


        _createSpreadForUsdc();
        _createAmmPoolsServiceUsdc();
        _createAmmOpenSwapServiceUsdc();
        _createAmmCloseSwapServiceUsdc();

        _createAmmPoolsLens();
        _createGovernanceService();
        _createAmmSwapsLens();
        _createAmmCloseSwapLens();

        _updateIporRouterImplementation();

        _setupIporProtocol();

        vm.stopPrank();

        _setupUser(PROTOCOL_OWNER, 1_000_000e6);

        _provideInitialLiquidity();
    }

    function _provideInitialLiquidity() private {
        address user = _getUserAddress(1223456789);

        vm.prank(0x62383739D68Dd0F844103Db8dFb05a7EdED5BBE6);
        ERC20(USDC).transfer(address(user), 10000 * 1e6);

        vm.prank(user);
        ERC20(USDC).approve(iporProtocolRouterProxy, 10000 * 1e6);

        vm.prank(user);
        IAmmPoolsServiceUsdc(iporProtocolRouterProxy).provideLiquidityUsdcToAmmPoolUsdc(user, 10000 * 1e6);
    }

    function _createAmmPoolsLens() private {
        ammPoolsLens = address(
            new AmmPoolsLensArbitrum(iporOracleProxy)
        );
    }

    function _createGovernanceService() internal {
        ammGovernanceService = address(
            new AmmGovernanceServiceArbitrum()
        );
    }

    function _createAmmSwapsLens() private {
        ammSwapsLens = address(
            new AmmSwapsLensArbitrum(iporOracleProxy)
        );
    }

    function _createAmmCloseSwapLens() private {
        ammCloseSwapLens = address(
            new AmmCloseSwapLensArbitrum(iporOracleProxy)
        );
    }

    function _createSpreadForUsdc() private {
        SpreadTypesBaseV1.TimeWeightedNotionalMemory[]
        memory timeWeightedNotionals = new SpreadTypesBaseV1.TimeWeightedNotionalMemory[](3);

        timeWeightedNotionals[0].storageId = SpreadStorageLibsBaseV1.StorageId.TimeWeightedNotional28Days;
        timeWeightedNotionals[1].storageId = SpreadStorageLibsBaseV1.StorageId.TimeWeightedNotional60Days;
        timeWeightedNotionals[2].storageId = SpreadStorageLibsBaseV1.StorageId.TimeWeightedNotional90Days;

        spreadUsdc = address(new SpreadBaseV1(iporProtocolRouterProxy, USDC, timeWeightedNotionals));
    }

    function _createAmmOpenSwapServiceUsdc() private {
        ammOpenSwapServiceUsdc = address(
            new AmmOpenSwapServiceUsdc({
                poolCfg: AmmTypesBaseV1.AmmOpenSwapServicePoolConfiguration({
                asset: USDC,
                decimals: IERC20MetadataUpgradeable(USDC).decimals(),
                ammStorage: ammStorageUsdcProxy,
                ammTreasury: ammTreasuryUsdcProxy,
                spread: spreadUsdc,
                iporPublicationFee: 10 * 1e15,
                maxSwapCollateralAmount: 100_000 * 1e18,
                liquidationDepositAmount: 1000,
                minLeverage: 10 * 1e18,
                openingFeeRate: 5e14,
                openingFeeTreasuryPortionRate: 5e17
            }),
                iporOracle_: iporOracleProxy
            })
        );
    }

    /// @dev case where liquidationDepositAmount is 0 and openingFeeRate is 0
    function _createAmmOpenSwapServiceUsdcCase2() internal {
        ammOpenSwapServiceUsdc = address(
            new AmmOpenSwapServiceUsdc({
                poolCfg: AmmTypesBaseV1.AmmOpenSwapServicePoolConfiguration({
                asset: USDC,
                decimals: IERC20MetadataUpgradeable(USDC).decimals(),
                ammStorage: ammStorageUsdcProxy,
                ammTreasury: ammTreasuryUsdcProxy,
                spread: spreadUsdc,
                iporPublicationFee: 5 * 1e15,
                maxSwapCollateralAmount: 50 * 1e18,
                liquidationDepositAmount: 0,
                minLeverage: 10 * 1e18,
                openingFeeRate: 0,
                openingFeeTreasuryPortionRate: 5e17
            }),
                iporOracle_: iporOracleProxy
            })
        );
    }

    function _createAmmCloseSwapServiceUsdc() private {
        ammCloseSwapServiceUsdc = address(
            new AmmCloseSwapServiceUsdc({
                poolCfg: IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration({
                asset: USDC,
                decimals: IERC20MetadataUpgradeable(USDC).decimals(),
                ammStorage: ammStorageUsdcProxy,
                ammTreasury: ammTreasuryUsdcProxy,
                assetManagement: ammAssetManagementUsdc,
                spread: spreadUsdc,
                unwindingFeeTreasuryPortionRate: 25e16,
                unwindingFeeRate: 5 * 1e11,
                maxLengthOfLiquidatedSwapsPerLeg: 10,
                timeBeforeMaturityAllowedToCloseSwapByCommunity: 1 hours,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor28days: 1 days,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor60days: 2 days,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor90days: 3 days,
                minLiquidationThresholdToCloseBeforeMaturityByCommunity: 995 * 1e15,
                minLiquidationThresholdToCloseBeforeMaturityByBuyer: 99 * 1e16,
                minLeverage: 10 * 1e18,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor28days: 1 days,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor60days: 2 days,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor90days: 3 days
            }),
                iporOracle_: iporOracleProxy
            })
        );
    }


    function _setupIporProtocol() internal {

        vm.startPrank(PROTOCOL_OWNER);
        IIporOracle(iporOracleProxy).addAsset(USDC, block.timestamp);

        address[] memory guardians = new address[](1);

        guardians[0] = PROTOCOL_OWNER;

        AmmTreasuryBaseV2(ammTreasuryUsdcProxy).addPauseGuardians(guardians);
        AmmTreasuryBaseV2(ammTreasuryUsdcProxy).unpause();

        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(USDC, 1000000000, 0, 0);

        IAmmGovernanceServiceArbitrum(iporProtocolRouterProxy).setMessageSigner(messageSignerAddress);

        IAmmGovernanceServiceArbitrum(iporProtocolRouterProxy).setAmmGovernancePoolConfiguration(USDC, StorageLibArbitrum.AssetGovernancePoolConfigValue({
            decimals: IERC20MetadataUpgradeable(USDC).decimals(),
            ammStorage: ammStorageUsdcProxy,
            ammTreasury: ammTreasuryUsdcProxy,
            ammVault: ammAssetManagementUsdc,
            ammPoolsTreasury: treasurer,
            ammPoolsTreasuryManager: treasurer,
            ammCharlieTreasury: treasurer,
            ammCharlieTreasuryManager: treasurer
        }
        ));

        IAmmGovernanceServiceArbitrum(iporProtocolRouterProxy).setAssetLensData(USDC, StorageLibArbitrum.AssetLensDataValue({
            decimals: IERC20MetadataUpgradeable(USDC).decimals(),
            ipToken: ipUsdc,
            ammStorage: ammStorageUsdcProxy,
            ammTreasury: ammTreasuryUsdcProxy,
            ammVault: ammAssetManagementUsdc,
            spread: address(0)
        }));

        IAmmGovernanceServiceArbitrum(iporProtocolRouterProxy).setAssetServices(USDC, StorageLibArbitrum.AssetServicesValue({
            ammPoolsService: ammPoolsServiceUsdc,
            ammOpenSwapService: ammOpenSwapServiceUsdc,
            ammCloseSwapService: ammCloseSwapServiceUsdc
        }));
    }

    function _setupAssetServices() internal {
        vm.prank(PROTOCOL_OWNER);
        IAmmGovernanceServiceArbitrum(iporProtocolRouterProxy).setAssetServices(USDC, StorageLibArbitrum.AssetServicesValue({
            ammPoolsService: ammPoolsServiceUsdc,
            ammOpenSwapService: ammOpenSwapServiceUsdc,
            ammCloseSwapService: ammCloseSwapServiceUsdc
        }));
    }

    function _createDummyContracts() internal {
        AmmTreasuryBaseV2 emptyImpl = new AmmTreasuryBaseV2(USDC, _defaultAddress, _defaultAddress, ammAssetManagementUsdc);

        ammTreasuryUsdcProxy = address(
            new ERC1967Proxy(address(emptyImpl), abi.encodeWithSignature("initialize(bool)", true))
        );
    }

    function _createIpToken() internal {
        ipUsdc = address(new IpToken("IP Usdc", "ipUsdc", USDC));
        IpToken(ipUsdc).setTokenManager(iporProtocolRouterProxy);
    }

    function _setupUser(address user, uint256 value) internal {
        deal(user, 1_000_000e18);

        vm.prank(0x62383739D68Dd0F844103Db8dFb05a7EdED5BBE6);
        ERC20(USDC).transfer(address(user), value);

        vm.prank(user);
        ERC20(USDC).approve(iporProtocolRouterProxy, value);
    }

    function _updateIporRouterImplementation() internal {
        IporProtocolRouterArbitrum.DeployedContractsArbitrum memory deployedContracts = IporProtocolRouterArbitrum
            .DeployedContractsArbitrum({
            ammSwapsLens: ammSwapsLens,
            ammPoolsLens: ammPoolsLens,
            ammCloseSwapLens: ammCloseSwapLens,
            ammGovernanceService: ammGovernanceService,
            liquidityMiningLens: _defaultAddress,
            powerTokenLens: _defaultAddress,
            flowService: _defaultAddress,
            stakeService: _defaultAddress,
            wstEth: wstETH,
            usdc: USDC,
            usdm: USDM
        });

        iporProtocolRouterImpl = address(new IporProtocolRouterArbitrum(deployedContracts));

        IporProtocolRouterArbitrum(payable(iporProtocolRouterProxy)).upgradeTo(iporProtocolRouterImpl);
    }

    function _getUserAddress(uint256 number) internal returns (address) {
        return vm.rememberKey(number);
    }

    function _createAmmPoolsServiceUsdc() private {
        ammPoolsServiceUsdc = address(
            new AmmPoolsServiceUsdc(
                {
                    asset_: USDC,
                    ipToken_: ipUsdc,
                    ammTreasury_: ammTreasuryUsdcProxy,
                    ammStorage_: ammStorageUsdcProxy,
                    ammAssetManagement_: ammAssetManagementUsdc,
                    iporOracle_: iporOracleProxy,
                    iporProtocolRouter_: iporProtocolRouterProxy,
                    redeemFeeRate_: 5 * 1e15,
                    autoRebalanceThresholdMultiplier_: 1000
                }
            ));
    }

    function _upgradeAmmTreasury() private {
        ammTreasuryUsdcImpl = address(new AmmTreasuryBaseV2(USDC, iporProtocolRouterProxy, ammStorageUsdcProxy, ammAssetManagementUsdc));
        AmmTreasuryBaseV2(ammTreasuryUsdcProxy).upgradeTo(ammTreasuryUsdcImpl);
    }

    function _createAmmStorage() private {
        ammStorageUsdcImpl = address(new AmmStorageBaseV1(iporProtocolRouterProxy));

        ammStorageUsdcProxy = address(
            new ERC1967Proxy(ammStorageUsdcImpl, abi.encodeWithSignature("initialize()", ""))
        );
    }

    function _createAmmAssetManagement() private {
        ammAssetManagementUsdc = address(new MockPlasmaVault(IERC20(USDC), "ipvUSDC", "ipvUSDC"));
    }

    function _createAmmPoolsServiceUsdc(uint redeemFeeRateAssetInput) internal {
        ammPoolsServiceUsdc = address(
            new AmmPoolsServiceUsdc(
                {
                    asset_: USDC,
                    ipToken_: ipUsdc,
                    ammTreasury_: ammTreasuryUsdcProxy,
                    ammStorage_: ammStorageUsdcProxy,
                    ammAssetManagement_: ammAssetManagementUsdc,
                    iporOracle_: iporOracleProxy,
                    iporProtocolRouter_: iporProtocolRouterProxy,
                    redeemFeeRate_: redeemFeeRateAssetInput,
                    autoRebalanceThresholdMultiplier_: 1000
                }

            ));
    }

    function _createNewAmmPoolsServiceUsdcWithZEROFee() internal {
        ammPoolsServiceUsdc = address(
            new AmmPoolsServiceUsdc({
                asset_: USDC,
                ipToken_: ipUsdc,
                ammTreasury_: ammTreasuryUsdcProxy,
                ammStorage_: ammStorageUsdcProxy,
                ammAssetManagement_: ammAssetManagementUsdc,
                iporOracle_: iporOracleProxy,
                iporProtocolRouter_: iporProtocolRouterProxy,
                redeemFeeRate_: 0,
                autoRebalanceThresholdMultiplier_: 1000
            })
        );
    }

    function _getCurrentTimestamps(
        address[] memory assets
    ) internal view returns (uint32[] memory lastUpdateTimestamps) {
        lastUpdateTimestamps = new uint32[](assets.length);

        uint32 lastUpdateTimestamp = uint32(block.timestamp);

        for (uint256 i = 0; i < assets.length; i++) {
            lastUpdateTimestamps[i] = lastUpdateTimestamp;
        }
    }


    function _prepareCloseSwapRiskIndicators(
        IporTypes.SwapTenor tenor
    ) internal view returns (AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs) {
        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputsPayFixed = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 25000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputsReceiveFixed = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 25000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 20000000000000000,
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputsPayFixed.signature = signRiskParams(
            riskIndicatorsInputsPayFixed,
            address(USDC),
            uint256(tenor),
            0,
            messageSignerPrivateKey
        );
        riskIndicatorsInputsReceiveFixed.signature = signRiskParams(
            riskIndicatorsInputsReceiveFixed,
            address(USDC),
            uint256(tenor),
            1,
            messageSignerPrivateKey
        );

        closeRiskIndicatorsInputs = AmmTypes.CloseSwapRiskIndicatorsInput({
            payFixed: riskIndicatorsInputsPayFixed,
            receiveFixed: riskIndicatorsInputsReceiveFixed
        });
    }

    function signRiskParams(
        AmmTypes.RiskIndicatorsInputs memory riskParamsInput,
        address asset,
        uint256 tenor,
        uint256 direction,
        uint256 privateKey
    ) internal pure returns (bytes memory) {
        // create digest: keccak256 gives us the first 32bytes after doing the hash
        // so this is always 32 bytes.
        bytes32 digest = keccak256(
            abi.encodePacked(
                riskParamsInput.maxCollateralRatio,
                riskParamsInput.maxCollateralRatioPerLeg,
                riskParamsInput.maxLeveragePerLeg,
                riskParamsInput.baseSpreadPerLeg,
                riskParamsInput.fixedRateCapPerLeg,
                riskParamsInput.demandSpreadFactor,
                riskParamsInput.expiration,
                asset,
                tenor,
                direction
            )
        );
        // r and s are the outputs of the ECDSA signature
        // r,s and v are packed into the signature. It should be 65 bytes: 32 + 32 + 1
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        // pack v, r, s into 65bytes signature
        // bytes memory signature = abi.encodePacked(r, s, v);
        return abi.encodePacked(r, s, v);
    }
}
