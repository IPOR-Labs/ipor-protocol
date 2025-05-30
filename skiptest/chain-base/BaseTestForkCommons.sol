// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IWETH9} from "../../contracts/amm-eth/interfaces/IWETH9.sol";

import "../../contracts/interfaces/IAmmCloseSwapLens.sol";
import "../../contracts/chains/ethereum/amm-commons/AmmSwapsLens.sol";
import "../../contracts/chains/arbitrum/amm-wstEth/AmmOpenSwapServiceWstEth.sol";
import "../../contracts/chains/arbitrum/amm-wstEth/AmmCloseSwapServiceWstEth.sol";
import "../../contracts/amm/AmmPoolsService.sol";
import "../../contracts/chains/arbitrum/amm-commons/AmmCloseSwapLensArbitrum.sol";
import "../../contracts/chains/arbitrum/amm-commons/AmmGovernanceServiceArbitrum.sol";
import {StorageLibArbitrum} from "../../contracts/chains/arbitrum/libraries/StorageLibArbitrum.sol";

import {AmmTreasuryBaseV2} from "../../contracts/base/amm/AmmTreasuryBaseV2.sol";


import {AmmPoolsServiceWstEthBaseV2} from "../../contracts/base/amm-wstEth/services/AmmPoolsServiceWstEthBaseV2.sol";

import {AmmCloseSwapServiceWstEthBaseV2} from "../../contracts/base/amm-wstEth/services/AmmCloseSwapServiceWstEthBaseV2.sol";

import {IporProtocolRouterBase} from "../../contracts/chains/base/router/IporProtocolRouterBase.sol";


interface IAccessManager {
    function grantRole(uint64 roleId, address account, uint32 executionDelay) external;
}

contract BaseTestForkCommons is Test {

    address private _defaultAddress = address(0x1234);
    address constant owner = address(0xF6a9bd8F6DC537675D499Ac1CA14f2c55d8b5569);
    address constant treasurer = address(0x888);

    address constant wstETH = 0xc1CBa3fCea344f92D9239c08C0568f6F2F0ee452;
    address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant ipwstETH = 0xff7907CDCA84DB03f09702A4A49C262908AF48Af;
    address constant iporOracleProxy = 0x85564fb392e18A84A64343A3FB65839206936C0f;
    address constant spreadWstEth = 0x3D21ADf3b0Ff5B3fDfFC8D5FFa6634Bd65949924;
    address constant ammSwapsLens = 0x6834BdFe5864c6B1703B999D04B092229A322943;
    address constant ammPoolsLens = 0xa4989A9225f6DD130e8Ce4a4b5ef7902c8c389dc;
    address constant ammCloseSwapLens = 0xB9C7A519BA2d6213F9E77f334b6aD8d8A2749CB9;
    address constant ammGovernanceService = 0x498eB532c9D3b4Cf20351b8767Dceb4B5D28FE4c;
    address constant iporProtocolRouterProxy = 0x21d337eBF86E584e614ecC18A2B1144D3C375918;

    address constant ammTreasuryWstEthProxy = 0x09388e18d5C331449C6eF636726dD1fd007b8DDf;
    address constant ammStorageWstEthProxy = 0x29399D76921e23314Ae259Cf5E17116f48AE65b7;
    
    address constant iporPlasmaVaultWstEth = 0xFe8b23B493579e5c3a0A3BC5BBF20662B3072DE6;
    address constant iporFusionAccessManagerWstEth = 0x3033C274D3Ccc8d12B4Ea567F6F94849507c37aE;

    uint64 constant WHITELIST_ROLE = 800;

    uint256 public messageSignerPrivateKey;
    address public messageSignerAddress;    
    
    address public iporProtocolRouterImpl;
    

    address public ammPoolsServiceWstEth;
    address public ammOpenSwapServiceWstEth;
    address public ammCloseSwapServiceWstEth;

    function _init() internal {
        messageSignerPrivateKey = 0x12341234;
        messageSignerAddress = vm.addr(messageSignerPrivateKey);

        _upgradeAmmTreasury();

        _createAmmPoolsServicesWstEth();

        ammOpenSwapServiceWstEth = 0xFbE094Bcc8731fa45Eb88850592248e5D6aC9472;

        // _createAmmOpenSwapServiceWstEth();
        _createAmmCloseSwapServiceWstEth();
        _setupAssetServices();

        _updateIporRouterImplementation();

        _setupIporProtocol();

        vm.prank(owner);
        IAccessManager(iporFusionAccessManagerWstEth).grantRole(WHITELIST_ROLE, ammTreasuryWstEthProxy, 0);

    }

    function _updateIporRouterImplementation() internal {
        IporProtocolRouterBase.DeployedContractsBase memory deployedContracts = IporProtocolRouterBase
            .DeployedContractsBase({
            ammSwapsLens: ammSwapsLens,
            ammPoolsLens: ammPoolsLens,
            ammCloseSwapLens: ammCloseSwapLens,
            ammGovernanceService: ammGovernanceService,

            liquidityMiningLens: _defaultAddress,
            powerTokenLens: _defaultAddress,
            flowService: _defaultAddress,
            stakeService: _defaultAddress,

            wstEth: wstETH,
            usdc: USDC
        });

        
        iporProtocolRouterImpl = address(new IporProtocolRouterBase(deployedContracts));

        vm.startPrank(owner);
        IporProtocolRouterBase(payable(iporProtocolRouterProxy)).upgradeTo(iporProtocolRouterImpl);
        vm.stopPrank();
    }

    function _setupIporProtocol() internal {

        vm.startPrank(owner);

        IAmmGovernanceServiceArbitrum(iporProtocolRouterProxy).setMessageSigner(messageSignerAddress);

        IAmmGovernanceServiceArbitrum(iporProtocolRouterProxy).setAmmGovernancePoolConfiguration(wstETH, StorageLibArbitrum.AssetGovernancePoolConfigValue({
            decimals: IERC20MetadataUpgradeable(wstETH).decimals(),
            ammStorage: ammStorageWstEthProxy,
            ammTreasury: ammTreasuryWstEthProxy,
            ammVault: iporPlasmaVaultWstEth,
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
            ammVault: iporPlasmaVaultWstEth,
            spread: spreadWstEth
        }));

        IAmmGovernanceServiceArbitrum(iporProtocolRouterProxy).setAssetServices(wstETH, StorageLibArbitrum.AssetServicesValue({
            ammPoolsService: ammPoolsServiceWstEth,
            ammOpenSwapService: ammOpenSwapServiceWstEth,
            ammCloseSwapService: ammCloseSwapServiceWstEth
        }));

        vm.stopPrank();

    }

    function _setupAssetServices() internal {
        vm.startPrank(0xF6a9bd8F6DC537675D499Ac1CA14f2c55d8b5569);
        IAmmGovernanceServiceArbitrum(iporProtocolRouterProxy).setAssetServices(wstETH, StorageLibArbitrum.AssetServicesValue({
            ammPoolsService: ammPoolsServiceWstEth,
            ammOpenSwapService: ammOpenSwapServiceWstEth,
            ammCloseSwapService: ammCloseSwapServiceWstEth
        }));
        vm.stopPrank();
    }

    function _setupUser(address user, uint256 value) internal {
        deal(user, 1_000_000e18);

        vm.startPrank(user);
        IWETH9(wstETH).approve(iporProtocolRouterProxy, type(uint256).max);
        vm.stopPrank();

    }

    function _getUserAddress(uint256 number) internal returns (address) {
        return vm.rememberKey(number);
    }


    function _createAmmPoolsServicesWstEth() private {
                
        ammPoolsServiceWstEth = address(
            new AmmPoolsServiceWstEthBaseV2({
                asset_: wstETH,
                ipToken_: ipwstETH,
                ammTreasury_: ammTreasuryWstEthProxy,
                ammStorage_: ammStorageWstEthProxy,
                ammAssetManagement_: iporPlasmaVaultWstEth,
                iporOracle_: iporOracleProxy,
                iporProtocolRouter_: iporProtocolRouterProxy,
                redeemFeeRate_: 5 * 1e15,
                autoRebalanceThresholdMultiplier_ : 1
            })
        );

    }

    
    function _upgradeAmmTreasury() private {
        
        address ammTreasuryWstEthImpl = address(new AmmTreasuryBaseV2(wstETH, iporProtocolRouterProxy, ammStorageWstEthProxy, iporPlasmaVaultWstEth));

        vm.prank(0xF6a9bd8F6DC537675D499Ac1CA14f2c55d8b5569);
        AmmTreasuryBaseV2(ammTreasuryWstEthProxy).upgradeTo(ammTreasuryWstEthImpl);
        
    }

    

    // function _createAmmOpenSwapServiceWstEth() private {
    //     ammOpenSwapServiceWstEth = address(
    //         new AmmOpenSwapServiceWstEth({
    //             poolCfg: AmmTypesBaseV1.AmmOpenSwapServicePoolConfiguration({
    //             asset: wstETH,
    //             decimals: IERC20MetadataUpgradeable(wstETH).decimals(),
    //             ammStorage: ammStorageWstEthProxy,
    //             ammTreasury: ammTreasuryWstEthProxy,
    //             spread: spreadWstEth,
    //             iporPublicationFee: 10 * 1e15,
    //             maxSwapCollateralAmount: 100_000 * 1e18,
    //             liquidationDepositAmount: 1000,
    //             minLeverage: 10 * 1e18,
    //             openingFeeRate: 5e14,
    //             openingFeeTreasuryPortionRate: 5e17
    //         }),
    //             iporOracle_: iporOracleProxy
    //         })
    //     );
    // }

    function _createAmmCloseSwapServiceWstEth() private {
        ammCloseSwapServiceWstEth = address(
            new AmmCloseSwapServiceWstEthBaseV2({
                poolCfg: IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration({
                    asset: wstETH,
                    decimals: IERC20MetadataUpgradeable(wstETH).decimals(),
                    ammStorage: ammStorageWstEthProxy,
                    ammTreasury: ammTreasuryWstEthProxy,
                    assetManagement: iporPlasmaVaultWstEth,
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
