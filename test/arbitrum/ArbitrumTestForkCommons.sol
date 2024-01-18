// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../../contracts/oracles/IporOracle.sol";
import "../mocks/EmptyRouterImplementation.sol";
import "../../contracts/chains/arbitrum/router/IporProtocolRouterArbitrum.sol";
import "../../contracts/interfaces/IAmmSwapsLens.sol";
import "../../contracts/interfaces/IAmmOpenSwapLens.sol";
import "../../contracts/interfaces/IAmmCloseSwapLens.sol";
import "../../contracts/chains/ethereum/amm-commons/AmmSwapsLens.sol";
import "../../contracts/amm/AmmPoolsLens.sol";
import "../../contracts/amm-eth/AmmPoolsLensWstEth.sol";
import "../../contracts/amm/AssetManagementLens.sol";
import "../../contracts/amm-eth/AmmOpenSwapServiceWstEth.sol";
import "../../contracts/amm-eth/AmmCloseSwapServiceWstEth.sol";
import "../../contracts/amm/AmmPoolsService.sol";
import "../../contracts/chains/arbitrum/amm-commons/AmmCloseSwapLensArbitrum.sol";
import "../../contracts/chains/arbitrum/amm-commons/AmmGovernanceServiceArbitrum.sol";
import "../../contracts/chains/arbitrum/amm-commons/AmmSwapsLensArbitrum.sol";

import "../../contracts/amm-eth/AmmPoolsServiceWstEth.sol";
import "../../contracts/base/amm/AmmStorageBaseV1.sol";
import "../../contracts/base/amm/AmmTreasuryBaseV1.sol";
import "../../contracts/base/spread/SpreadBaseV1.sol";

import "../../contracts/tokens/IpToken.sol";
import "./interfaces/IERC20Bridged.sol";

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

    uint256 public messageSignerPrivateKey;
    address public messageSignerAddress;

    address public ammTreasuryWstEthImpl;
    address public ammTreasuryWstEthProxy;
    address public ammStorageWstEthImpl;
    address public ammStorageWstEthProxy;

    address public iporProtocolRouterImpl;
    address public iporProtocolRouterProxy;

    address public ipwstETH;
    address public spreadWstEth;

    address public ammGovernanceService;
    address public ammSwapsLens;
    address public ammPoolsLensWstEth;
    address public ammPoolsServiceWstEth;
    address public ammOpenSwapServiceWstEth;
    address public ammCloseSwapServiceWstEth;
    address public ammCloseSwapLens;

    address public iporOracleImpl;
    address public iporOracleProxy;

    function _init() internal {
        messageSignerPrivateKey = 0x12341234;
        messageSignerAddress = vm.addr(messageSignerPrivateKey);

        _createDummyContracts();
        _createIpToken();
        _createIporOracle();
        _createAmmStorageWstEth();
        _createSpreadForWstEth();

        _upgradeAmmTreasuryWstEth();

        _createAmmSwapsLens();
        _createAmmOpenSwapServiceWstEth();
        _createAmmCloseSwapServiceWstEth();
        _createAmmCloseSwapLens();
        _createGovernanceService();
        _createAmmPoolsServiceWstEth();
        _createAmmPoolsLensWstEth();

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
    }

    function _createGovernanceService() internal {
        ammGovernanceService = address(
            new AmmGovernanceServiceArbitrum({
                wstEthPoolCfg: IAmmGovernanceLens.AmmGovernancePoolConfiguration({
                    asset: wstETH,
                    decimals: IERC20MetadataUpgradeable(wstETH).decimals(),
                    ammStorage: ammStorageWstEthProxy,
                    ammTreasury: ammTreasuryWstEthProxy,
                    ammPoolsTreasury: treasurer,
                    ammPoolsTreasuryManager: treasurer,
                    ammCharlieTreasury: treasurer,
                    ammCharlieTreasuryManager: treasurer
                })
            })
        );
    }

    function _createDummyContracts() internal {
        IporProtocolRouterArbitrum.DeployedContractsArbitrum memory deployedContracts = IporProtocolRouterArbitrum
            .DeployedContractsArbitrum({
                ammSwapsLens: _defaultAddress,
                ammOpenSwapServiceWstEth: _defaultAddress,
                ammCloseSwapServiceWstEth: _defaultAddress,
                ammCloseSwapLens: _defaultAddress,
                ammGovernanceService: _defaultAddress,
                liquidityMiningLens: _defaultAddress,
                powerTokenLens: _defaultAddress,
                flowService: _defaultAddress,
                stakeService: _defaultAddress,
                ammPoolsServiceWstEth: _defaultAddress,
                ammPoolsLensWstEth: _defaultAddress
            });

        iporProtocolRouterImpl = address(new IporProtocolRouterArbitrum(deployedContracts));

        iporProtocolRouterProxy = payable(
            new ERC1967Proxy(iporProtocolRouterImpl, abi.encodeWithSignature("initialize(bool)", false))
        );

        AmmTreasuryBaseV1 emptyImpl = new AmmTreasuryBaseV1(_defaultAddress, _defaultAddress, _defaultAddress);

        ammTreasuryWstEthProxy = address(
            new ERC1967Proxy(address(emptyImpl), abi.encodeWithSignature("initialize(bool)", true))
        );
    }

    function _createIpToken() internal {
        ipwstETH = address(new IpToken("IP wstETH", "ipwstETH", wstETH));
        IpToken(ipwstETH).setTokenManager(iporProtocolRouterProxy);
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
                ammOpenSwapServiceWstEth: ammOpenSwapServiceWstEth,
                ammCloseSwapServiceWstEth: ammCloseSwapServiceWstEth,
                ammCloseSwapLens: ammCloseSwapLens,
                ammGovernanceService: ammGovernanceService,
                liquidityMiningLens: _defaultAddress,
                powerTokenLens: _defaultAddress,
                flowService: _defaultAddress,
                stakeService: _defaultAddress,
                ammPoolsServiceWstEth: ammPoolsServiceWstEth,
                ammPoolsLensWstEth: ammPoolsLensWstEth
            });

        iporProtocolRouterImpl = address(new IporProtocolRouterArbitrum(deployedContracts));

        IporProtocolRouterArbitrum(payable(iporProtocolRouterProxy)).upgradeTo(iporProtocolRouterImpl);
    }

    function _getUserAddress(uint256 number) internal returns (address) {
        return vm.rememberKey(number);
    }

    function _createAmmSwapsLens() private {
        ammSwapsLens = address(
            new AmmSwapsLensArbitrum({
                wstEthCfg: IAmmSwapsLens.SwapLensPoolConfiguration({
                    asset: wstETH,
                    ammStorage: ammStorageWstEthProxy,
                    ammTreasury: ammTreasuryWstEthProxy,
                    spread: spreadWstEth
                }),
                iporOracleInput: iporOracleProxy,
                messageSignerInput: messageSignerAddress
            })
        );
    }

    function _createAmmPoolsLensWstEth() private {
        ammPoolsLensWstEth = address(
            new AmmPoolsLensWstEth({
                wstEthInput: wstETH,
                ipwstEthInput: ipwstETH,
                ammTreasuryWstEthInput: ammTreasuryWstEthProxy,
                ammStorageWstEthInput: ammStorageWstEthProxy,
                iporOracleInput: iporOracleProxy
            })
        );
    }

    function _createAmmPoolsServiceWstEth() private {
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

    function _upgradeAmmTreasuryWstEth() private {
        ammTreasuryWstEthImpl = address(new AmmTreasuryBaseV1(wstETH, iporProtocolRouterProxy, ammStorageWstEthProxy));
        AmmTreasuryBaseV1(ammTreasuryWstEthProxy).upgradeTo(ammTreasuryWstEthImpl);
    }

    function _createAmmStorageWstEth() private {
        ammStorageWstEthImpl = address(new AmmStorageBaseV1(iporProtocolRouterProxy));

        ammStorageWstEthProxy = address(
            new ERC1967Proxy(ammStorageWstEthImpl, abi.encodeWithSignature("initialize()", ""))
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
                iporOracleInput: iporOracleProxy,
                messageSignerInput: messageSignerAddress,
                wstETHInput: wstETH
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
                iporOracleInput: iporOracleProxy,
                messageSignerInput: messageSignerAddress,
                wstETHInput: wstETH
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
                iporOracleInput: iporOracleProxy,
                messageSignerInput: messageSignerAddress,
                wstETHInput: wstETH
            })
        );
    }

    function _createAmmCloseSwapLens() private {
        ammCloseSwapLens = address(
            new AmmCloseSwapLensArbitrum({
                wstETHInput: wstETH,
                iporOracleInput: iporOracleProxy,
                messageSignerInput: messageSignerAddress,
                closeSwapServiceWstEthInput: ammCloseSwapServiceWstEth
            })
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
                    unwindingFeeTreasuryPortionRate: 5 * 1e17,
                    unwindingFeeRate: 5 * 1e14,
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
                iporOracleInput: iporOracleProxy,
                messageSignerInput: messageSignerAddress
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
                iporOracleInput: iporOracleProxy,
                messageSignerInput: messageSignerAddress
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
