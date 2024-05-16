// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IWETH9} from "../../contracts/amm-eth/interfaces/IWETH9.sol";

import "../../contracts/oracles/IporOracle.sol";
import "../../contracts/chains/arbitrum/router/IporProtocolRouterArbitrum.sol";
import "../../contracts/interfaces/IAmmCloseSwapLens.sol";
import "../../contracts/chains/ethereum/amm-commons/AmmSwapsLens.sol";
import "../../contracts/chains/arbitrum/amm-wstEth/AmmOpenSwapServiceWstEth.sol";
import "../../contracts/chains/arbitrum/amm-wstEth/AmmCloseSwapServiceWstEth.sol";
import "../../contracts/amm/AmmPoolsService.sol";
import "../../contracts/chains/arbitrum/amm-commons/AmmCloseSwapLensArbitrum.sol";
import "../../contracts/chains/arbitrum/amm-commons/AmmGovernanceServiceArbitrum.sol";
import "../../contracts/chains/arbitrum/amm-commons/AmmSwapsLensArbitrum.sol";
import {StorageLibArbitrum} from "../../contracts/chains/arbitrum/libraries/StorageLibArbitrum.sol";

import "../../contracts/amm-eth/AmmPoolsServiceWstEth.sol";
import "../../contracts/base/amm/AmmStorageBaseV1.sol";
import "../../contracts/base/amm/AmmTreasuryBaseV1.sol";
import "../../contracts/base/spread/SpreadBaseV1.sol";

import "../../contracts/tokens/IpToken.sol";
import "./interfaces/IERC20Bridged.sol";
import {AmmPoolsLensArbitrum} from "../../contracts/chains/arbitrum/amm-commons/AmmPoolsLensArbitrum.sol";

import {AmmPoolsServiceUsdm} from "../../contracts/amm-usdm/AmmPoolsServiceUsdm.sol";

contract ArbitrumTestForkCommons is Test {
    address internal constant WST_ETH_BRIDGE = 0x07D4692291B9E30E326fd31706f686f83f331B82;

    address private _defaultAddress = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;

    address public constant owner = 0xD92E9F039E4189c342b4067CC61f5d063960D248;
    address public treasurer = _getUserAddress(555);

    address public constant IPOR = 0x34229B3f16fBCDfA8d8d9d17C0852F9496f4C7BB;

    address public constant DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address public constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    address public constant wstETH = 0x5979D7b546E38E414F7E9822514be443A4800529;
    address public constant USDM = 0x59D9356E565Ab3A36dD77763Fc0d87fEaf85508C;

    uint256 public messageSignerPrivateKey;
    address public messageSignerAddress;

    address public ammTreasuryWstEthImpl;
    address public ammTreasuryWstEthProxy;
    address public ammStorageWstEthImpl;
    address public ammStorageWstEthProxy;

    address public ammTreasuryUsdmImpl;
    address public ammTreasuryUsdmProxy;
    address public ammStorageUsdmImpl;
    address public ammStorageUsdmProxy;

    address public iporProtocolRouterImpl;
    address public iporProtocolRouterProxy;

    address public ipwstETH;
    address public spreadWstEth;

    address public ipUsdm;

    address public ammSwapsLens;
    address public ammPoolsLens;
    address public ammCloseSwapLens;
    address public ammGovernanceService;

    address public ammPoolsServiceWstEth;
    address public ammOpenSwapServiceWstEth;
    address public ammCloseSwapServiceWstEth;

    address public ammPoolsServiceUsdc;
    address public ammOpenSwapServiceUsdc;
    address public ammCloseSwapServiceUsdc;

    address public ammPoolsServiceUsdm;
    address public ammOpenSwapServiceUsdm = _defaultAddress;
    address public ammCloseSwapServiceUsdm = _defaultAddress;

    address public iporOracleImpl;
    address public iporOracleProxy;

    function _init() internal {
        messageSignerPrivateKey = 0x12341234;
        messageSignerAddress = vm.addr(messageSignerPrivateKey);

        _createDummyContracts();
        _createIpToken();
        _createIporOracle();
        _createAmmStorage();
        _createSpreadForWstEth();

        _upgradeAmmTreasury();

        _createAmmSwapsLens();
        _createAmmPoolsLens();
        _createAmmCloseSwapLens();

        _createGovernanceService();

        _createAmmPoolsServices();
        _createAmmOpenSwapServiceWstEth();
        _createAmmCloseSwapServiceWstEth();

        _updateIporRouterImplementation();

        _setupIporProtocol();

        _setupUser(owner, 1_000_000e18);

        vm.startPrank(owner);
        IAmmPoolsServiceWstEth(iporProtocolRouterProxy).provideLiquidityWstEth(owner, 1608191730290969156689);
        vm.stopPrank();
    }

    function _setupIporProtocol() internal {
        address[] memory guardians = new address[](1);

        guardians[0] = owner;
        AmmTreasuryBaseV1(ammTreasuryWstEthProxy).addPauseGuardians(guardians);
        AmmTreasuryBaseV1(ammTreasuryWstEthProxy).unpause();

        IAmmGovernanceService(iporProtocolRouterProxy).setAmmPoolsParams(wstETH, 1000000000, 0, 0);

        IAmmGovernanceServiceArbitrum(iporProtocolRouterProxy).setMessageSigner(messageSignerAddress);

        IAmmGovernanceServiceArbitrum(iporProtocolRouterProxy).setAmmGovernancePoolConfiguration(wstETH, StorageLibArbitrum.AssetGovernancePoolConfigValue({
            decimals: IERC20MetadataUpgradeable(wstETH).decimals(),
            ammStorage: ammStorageWstEthProxy,
            ammTreasury: ammTreasuryWstEthProxy,
            vault: address(0),
            ammPoolsTreasury: treasurer,
            ammPoolsTreasuryManager: treasurer,
            ammCharlieTreasury: treasurer,
            ammCharlieTreasuryManager: treasurer
        }
        ));

        IAmmGovernanceServiceArbitrum(iporProtocolRouterProxy).setAssetLensData(wstETH, StorageLibArbitrum.AssetLensDataValue({
            decimals: IERC20MetadataUpgradeable(wstETH).decimals(),
            ipToken: ipwstETH,
            ammStorage: ammStorageWstEthProxy,
            ammTreasury: ammTreasuryWstEthProxy,
            spread: spreadWstEth,
            vault: address(0)
        }));

        IAmmGovernanceServiceArbitrum(iporProtocolRouterProxy).setAssetServices(wstETH, StorageLibArbitrum.AssetServicesValue({
            ammPoolsService: ammPoolsServiceWstEth,
            ammOpenSwapService: ammOpenSwapServiceWstEth,
            ammCloseSwapService: ammCloseSwapServiceWstEth
        }));

    }

    function _setupAssetServices() internal {
        IAmmGovernanceServiceArbitrum(iporProtocolRouterProxy).setAssetServices(wstETH, StorageLibArbitrum.AssetServicesValue({
            ammPoolsService: ammPoolsServiceWstEth,
            ammOpenSwapService: ammOpenSwapServiceWstEth,
            ammCloseSwapService: ammCloseSwapServiceWstEth
        }));
    }

    function _createGovernanceService() internal {
        ammGovernanceService = address(
            new AmmGovernanceServiceArbitrum()
        );
    }

    function _createDummyContracts() internal {
        IporProtocolRouterArbitrum.DeployedContractsArbitrum memory deployedContracts = IporProtocolRouterArbitrum
            .DeployedContractsArbitrum({
            ammSwapsLens: _defaultAddress,
            ammPoolsLens: _defaultAddress,
            ammCloseSwapLens: _defaultAddress,
            ammGovernanceService: _defaultAddress,

            liquidityMiningLens: _defaultAddress,
            powerTokenLens: _defaultAddress,
            flowService: _defaultAddress,
            stakeService: _defaultAddress,

            wstEth: wstETH,
            usdc: USDC,
            usdm: USDM
        });

        iporProtocolRouterImpl = address(new IporProtocolRouterArbitrum(deployedContracts));

        iporProtocolRouterProxy = payable(
            new ERC1967Proxy(iporProtocolRouterImpl, abi.encodeWithSignature("initialize(bool)", false))
        );

        AmmTreasuryBaseV1 emptyImpl = new AmmTreasuryBaseV1(wstETH, _defaultAddress, _defaultAddress);

        ammTreasuryWstEthProxy = address(
            new ERC1967Proxy(address(emptyImpl), abi.encodeWithSignature("initialize(bool)", true))
        );

        ammTreasuryUsdmProxy = address(
            new ERC1967Proxy(address(emptyImpl), abi.encodeWithSignature("initialize(bool)", true))
        );
    }

    function _createIpToken() internal {
        ipwstETH = address(new IpToken("IP wstETH", "ipwstETH", wstETH));
        IpToken(ipwstETH).setTokenManager(iporProtocolRouterProxy);
        ipUsdm = address(new IpToken("IP Usdm", "ipUsdm", USDM));
        IpToken(ipUsdm).setTokenManager(iporProtocolRouterProxy);
    }

    function _setupUser(address user, uint256 value) internal {
        deal(user, 1_000_000e18);

        vm.startPrank(user);
        IWETH9(wstETH).approve(iporProtocolRouterProxy, type(uint256).max);
        vm.stopPrank();

        vm.prank(WST_ETH_BRIDGE);
        IERC20Bridged(wstETH).bridgeMint(user, value);
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

    function _createAmmSwapsLens() private {
        ammSwapsLens = address(
            new AmmSwapsLensArbitrum(iporOracleProxy)
        );
    }

    function _createAmmPoolsLens() private {
        ammPoolsLens = address(
            new AmmPoolsLensArbitrum(iporOracleProxy)
        );
    }

    function _createAmmPoolsServices() private {
        ammPoolsServiceWstEth = address(
            new AmmPoolsServiceWstEth({
                wstEthInput: wstETH,
                ipwstEthInput: ipwstETH,
                ammTreasuryWstEthInput: ammTreasuryWstEthProxy,
                ammStorageWstEthInput: ammStorageWstEthProxy,
                iporOracleInput: iporOracleProxy,
                iporProtocolRouterInput: iporProtocolRouterProxy,
                redeemFeeRateWstEthInput: 5 * 1e15
            })
        );

        ammPoolsServiceUsdm = address(
            new AmmPoolsServiceUsdm({
                usdmInput: USDM,
                ipUsdmInput: ipUsdm,
                ammTreasuryUsdmInput: ammTreasuryUsdmProxy,
                ammStorageUsdmInput: ammStorageUsdmProxy,
                iporOracleInput: iporOracleProxy,
                iporProtocolRouterInput: iporProtocolRouterProxy,
                redeemFeeRateUsdmInput: 5 * 1e15
            })
        );
    }

    function _createNewAmmPoolsServiceWstEthWithZEROFee() internal {
        ammPoolsServiceWstEth = address(
            new AmmPoolsServiceWstEth({
                wstEthInput: wstETH,
                ipwstEthInput: ipwstETH,
                ammTreasuryWstEthInput: ammTreasuryWstEthProxy,
                ammStorageWstEthInput: ammStorageWstEthProxy,
                iporOracleInput: iporOracleProxy,
                iporProtocolRouterInput: iporProtocolRouterProxy,
                redeemFeeRateWstEthInput: 0
            })
        );
    }

    function _upgradeAmmTreasury() private {
        ammTreasuryWstEthImpl = address(new AmmTreasuryBaseV1(wstETH, iporProtocolRouterProxy, ammStorageWstEthProxy));
        AmmTreasuryBaseV1(ammTreasuryWstEthProxy).upgradeTo(ammTreasuryWstEthImpl);
        ammTreasuryUsdmImpl = address(new AmmTreasuryBaseV1(USDM, iporProtocolRouterProxy, ammStorageUsdmProxy));
        AmmTreasuryBaseV1(ammTreasuryUsdmProxy).upgradeTo(ammTreasuryUsdmImpl);
    }

    function _createAmmStorage() private {
        ammStorageWstEthImpl = address(new AmmStorageBaseV1(iporProtocolRouterProxy));

        ammStorageWstEthProxy = address(
            new ERC1967Proxy(ammStorageWstEthImpl, abi.encodeWithSignature("initialize()", ""))
        );
        ammStorageUsdmImpl = address(new AmmStorageBaseV1(iporProtocolRouterProxy));

        ammStorageUsdmProxy = address(
            new ERC1967Proxy(ammStorageUsdmImpl, abi.encodeWithSignature("initialize()", ""))
        );
    }

    function _createAmmOpenSwapServiceWstEth() private {
        ammOpenSwapServiceWstEth = address(
            new AmmOpenSwapServiceWstEth({
                poolCfg: AmmTypesBaseV1.AmmOpenSwapServicePoolConfiguration({
                asset: wstETH,
                decimals: IERC20MetadataUpgradeable(wstETH).decimals(),
                ammStorage: ammStorageWstEthProxy,
                ammTreasury: ammTreasuryWstEthProxy,
                spread: spreadWstEth,
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
    function _createAmmOpenSwapServiceWstEthCase2() internal {
        ammOpenSwapServiceWstEth = address(
            new AmmOpenSwapServiceWstEth({
                poolCfg: AmmTypesBaseV1.AmmOpenSwapServicePoolConfiguration({
                asset: wstETH,
                decimals: IERC20MetadataUpgradeable(wstETH).decimals(),
                ammStorage: ammStorageWstEthProxy,
                ammTreasury: ammTreasuryWstEthProxy,
                spread: spreadWstEth,
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

    /// @dev case where liquidationDepositAmount openingFeeRate is 0
    function _createAmmOpenSwapServiceWstEthCase3() internal {
        ammOpenSwapServiceWstEth = address(
            new AmmOpenSwapServiceWstEth({
                poolCfg: AmmTypesBaseV1.AmmOpenSwapServicePoolConfiguration({
                asset: wstETH,
                decimals: IERC20MetadataUpgradeable(wstETH).decimals(),
                ammStorage: ammStorageWstEthProxy,
                ammTreasury: ammTreasuryWstEthProxy,
                spread: spreadWstEth,
                iporPublicationFee: 5 * 1e15,
                maxSwapCollateralAmount: 50 * 1e18,
                liquidationDepositAmount: 10000,
                minLeverage: 10 * 1e18,
                openingFeeRate: 0,
                openingFeeTreasuryPortionRate: 5e17
            }),
                iporOracle_: iporOracleProxy
            })
        );
    }

    function _createAmmCloseSwapLens() private {
        ammCloseSwapLens = address(
            new AmmCloseSwapLensArbitrum(iporOracleProxy)
        );
    }

    function _createAmmCloseSwapServiceWstEth() private {
        ammCloseSwapServiceWstEth = address(
            new AmmCloseSwapServiceWstEth({
                poolCfg: IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration({
                asset: wstETH,
                decimals: IERC20MetadataUpgradeable(wstETH).decimals(),
                ammStorage: ammStorageWstEthProxy,
                ammTreasury: ammTreasuryWstEthProxy,
                assetManagement: address(0),
                spread: spreadWstEth,
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

    function _createAmmCloseSwapServiceStEthUnwindCase1() internal {
        ammCloseSwapServiceWstEth = address(
            new AmmCloseSwapServiceWstEth({
                poolCfg: IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration({
                asset: wstETH,
                decimals: IERC20MetadataUpgradeable(wstETH).decimals(),
                ammStorage: ammStorageWstEthProxy,
                ammTreasury: ammTreasuryWstEthProxy,
                assetManagement: address(0),
                spread: spreadWstEth,
                unwindingFeeTreasuryPortionRate: 5 * 1e17,
                unwindingFeeRate: 5 * 1e14,
                maxLengthOfLiquidatedSwapsPerLeg: 10,
                timeBeforeMaturityAllowedToCloseSwapByCommunity: 1 hours,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor28days: 1 days,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor60days: 3 days,
                timeBeforeMaturityAllowedToCloseSwapByBuyerTenor90days: 3 days,
                minLiquidationThresholdToCloseBeforeMaturityByCommunity: 995 * 1e15,
                minLiquidationThresholdToCloseBeforeMaturityByBuyer: 99 * 1e16,
                minLeverage: 10 * 1e18,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor28days: 1 days,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor60days: 60 days,
                timeAfterOpenAllowedToCloseSwapWithUnwindingTenor90days: 90 days
            }),
                iporOracle_: iporOracleProxy
            })
        );
    }

    function _createSpreadForWstEth() private {
        SpreadTypesBaseV1.TimeWeightedNotionalMemory[]
        memory timeWeightedNotionals = new SpreadTypesBaseV1.TimeWeightedNotionalMemory[](3);

        timeWeightedNotionals[0].storageId = SpreadStorageLibsBaseV1.StorageId.TimeWeightedNotional28Days;
        timeWeightedNotionals[1].storageId = SpreadStorageLibsBaseV1.StorageId.TimeWeightedNotional60Days;
        timeWeightedNotionals[2].storageId = SpreadStorageLibsBaseV1.StorageId.TimeWeightedNotional90Days;

        spreadWstEth = address(new SpreadBaseV1(iporProtocolRouterProxy, wstETH, timeWeightedNotionals));
    }

    function _createIporOracle() private {
        address[] memory assets = new address[](1);
        assets[0] = wstETH;

        iporOracleImpl = address(new IporOracle(USDT, 1e18, USDC, 1e18, DAI, 1e18));

        /// @dev timestamp higher than 0 means that asset is supported otherwise not,
        /// in our case only wstETH will be supported
        uint32[] memory lastUpdateTimestamps = _getCurrentTimestamps(assets);

        iporOracleProxy = address(
            new ERC1967Proxy(
                iporOracleImpl,
                abi.encodeWithSignature("initialize(address[],uint32[])", assets, lastUpdateTimestamps)
            )
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
            address(wstETH),
            uint256(tenor),
            0,
            messageSignerPrivateKey
        );
        riskIndicatorsInputsReceiveFixed.signature = signRiskParams(
            riskIndicatorsInputsReceiveFixed,
            address(wstETH),
            uint256(tenor),
            1,
            messageSignerPrivateKey
        );

        closeRiskIndicatorsInputs = AmmTypes.CloseSwapRiskIndicatorsInput({
            payFixed: riskIndicatorsInputsPayFixed,
            receiveFixed: riskIndicatorsInputsReceiveFixed
        });
    }

    function _prepareCloseSwapRiskIndicatorsHighFixedRateCaps(
        IporTypes.SwapTenor tenor
    ) internal view returns (AmmTypes.CloseSwapRiskIndicatorsInput memory closeRiskIndicatorsInputs) {
        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputsPayFixed = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 25000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 300000000000000000, /// @dev 30%
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        AmmTypes.RiskIndicatorsInputs memory riskIndicatorsInputsReceiveFixed = AmmTypes.RiskIndicatorsInputs({
            maxCollateralRatio: 50000000000000000,
            maxCollateralRatioPerLeg: 25000000000000000,
            maxLeveragePerLeg: 1000000000000000000000,
            baseSpreadPerLeg: 3695000000000000,
            fixedRateCapPerLeg: 300000000000000000, /// @dev 30%
            demandSpreadFactor: 20,
            expiration: block.timestamp + 1000,
            signature: bytes("0x00")
        });

        riskIndicatorsInputsPayFixed.signature = signRiskParams(
            riskIndicatorsInputsPayFixed,
            address(wstETH),
            uint256(tenor),
            0,
            messageSignerPrivateKey
        );
        riskIndicatorsInputsReceiveFixed.signature = signRiskParams(
            riskIndicatorsInputsReceiveFixed,
            address(wstETH),
            uint256(tenor),
            1,
            messageSignerPrivateKey
        );

        closeRiskIndicatorsInputs = AmmTypes.CloseSwapRiskIndicatorsInput({
            payFixed: riskIndicatorsInputsPayFixed,
            receiveFixed: riskIndicatorsInputsReceiveFixed
        });
    }

    function getIndexToUpdate(
        address asset,
        uint indexValue
    ) internal pure returns (IIporOracle.UpdateIndexParams[] memory) {
        IIporOracle.UpdateIndexParams[] memory updateIndexParams = new IIporOracle.UpdateIndexParams[](1);
        updateIndexParams[0] = IIporOracle.UpdateIndexParams({
            asset: asset,
            indexValue: indexValue,
            updateTimestamp: 0,
            quasiIbtPrice: 0
        });
        return updateIndexParams;
    }
}
