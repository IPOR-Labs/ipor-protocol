//  SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "contracts/oracles/IporRiskManagementOracle.sol";
import "../TestConstants.sol";
import "forge-std/Test.sol";
import "./BuilderUtils.sol";
import "../../../contracts/interfaces/types/IporRiskManagementOracleTypes.sol";

contract IporRiskManagementOracleBuilder is Test {
    address[] private _assets;
    mapping(address => IporRiskManagementOracleTypes.RiskIndicators) private _riskIndicators;
    mapping(address => IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps) private _baseSpreads;

    address private _owner;

    constructor(address owner) {
        _owner = owner;
    }

    function withAssetAndDefaultIndicators(address asset) public returns (IporRiskManagementOracleBuilder) {
        return
            withAsset(
                asset,
                IporRiskManagementOracleTypes.RiskIndicators({
                    maxNotionalPayFixed: TestConstants.RMO_NOTIONAL_1B,
                    maxNotionalReceiveFixed: TestConstants.RMO_NOTIONAL_1B,
                    maxCollateralRatioPayFixed: TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                    maxCollateralRatioReceiveFixed: TestConstants.RMO_COLLATERAL_RATIO_48_PER,
                    maxCollateralRatio: TestConstants.RMO_COLLATERAL_RATIO_90_PER
                }),
                IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps({
                    spread28dPayFixed: TestConstants.RMO_SPREAD_0_1_PER,
                    spread28dReceiveFixed: TestConstants.RMO_SPREAD_0_1_PER,
                    spread60dPayFixed: TestConstants.RMO_SPREAD_0_1_PER,
                    spread60dReceiveFixed: TestConstants.RMO_SPREAD_0_1_PER,
                    spread90dPayFixed: TestConstants.RMO_SPREAD_0_1_PER,
                    spread90dReceiveFixed: TestConstants.RMO_SPREAD_0_1_PER,
                    fixedRateCap28dPayFixed: TestConstants.RMO_FIXED_RATE_CAP_2_0_PER,
                    fixedRateCap28dReceiveFixed: TestConstants.RMO_FIXED_RATE_CAP_3_5_PER,
                    fixedRateCap60dPayFixed: TestConstants.RMO_FIXED_RATE_CAP_2_0_PER,
                    fixedRateCap60dReceiveFixed: TestConstants.RMO_FIXED_RATE_CAP_3_5_PER,
                    fixedRateCap90dPayFixed: TestConstants.RMO_FIXED_RATE_CAP_2_0_PER,
                    fixedRateCap90dReceiveFixed: TestConstants.RMO_FIXED_RATE_CAP_3_5_PER
                })
            );
    }

    function withAsset(
        address asset,
        IporRiskManagementOracleTypes.RiskIndicators memory riskIndicators,
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps memory baseSpreads
    ) public returns (IporRiskManagementOracleBuilder) {
        address[] memory _oldAssets = _assets;
        _assets = new address[](_assets.length + 1);
        for (uint256 i; i < _oldAssets.length; i++) {
            _assets[i] = _oldAssets[i];
        }
        _assets[_assets.length - 1] = asset;
        _riskIndicators[asset] = riskIndicators;
        _baseSpreads[asset] = baseSpreads;
        return this;
    }

    function build() public returns (IporRiskManagementOracle) {
        vm.startPrank(_owner);
        ERC1967Proxy proxy = _constructProxy(address(new IporRiskManagementOracle()));
        IporRiskManagementOracle oracle = IporRiskManagementOracle(address(proxy));
        vm.stopPrank();
        delete _assets;
        return oracle;
    }

    function _constructProxy(address impl) internal returns (ERC1967Proxy proxy) {
        IporRiskManagementOracleTypes.RiskIndicators[]
            memory riskIndicators = new IporRiskManagementOracleTypes.RiskIndicators[](_assets.length);
        IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps[]
            memory baseSpreadsAndFixedRateCaps = new IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps[](
                _assets.length
            );

        for (uint256 i; i < _assets.length; i++) {
            riskIndicators[i] = IporRiskManagementOracleTypes.RiskIndicators({
                maxNotionalPayFixed: _riskIndicators[_assets[i]].maxNotionalPayFixed,
                maxNotionalReceiveFixed: _riskIndicators[_assets[i]].maxNotionalReceiveFixed,
                maxCollateralRatioPayFixed: _riskIndicators[_assets[i]].maxCollateralRatioPayFixed,
                maxCollateralRatioReceiveFixed: _riskIndicators[_assets[i]].maxCollateralRatioReceiveFixed,
                maxCollateralRatio: _riskIndicators[_assets[i]].maxCollateralRatio
            });
            baseSpreadsAndFixedRateCaps[i] = IporRiskManagementOracleTypes.BaseSpreadsAndFixedRateCaps({
                spread28dPayFixed: _baseSpreads[_assets[i]].spread28dPayFixed,
                spread28dReceiveFixed: _baseSpreads[_assets[i]].spread28dReceiveFixed,
                spread60dPayFixed: _baseSpreads[_assets[i]].spread60dPayFixed,
                spread60dReceiveFixed: _baseSpreads[_assets[i]].spread60dReceiveFixed,
                spread90dPayFixed: _baseSpreads[_assets[i]].spread90dPayFixed,
                spread90dReceiveFixed: _baseSpreads[_assets[i]].spread90dReceiveFixed,
                fixedRateCap28dPayFixed: _baseSpreads[_assets[i]].fixedRateCap28dPayFixed,
                fixedRateCap28dReceiveFixed: _baseSpreads[_assets[i]].fixedRateCap28dReceiveFixed,
                fixedRateCap60dPayFixed: _baseSpreads[_assets[i]].fixedRateCap60dPayFixed,
                fixedRateCap60dReceiveFixed: _baseSpreads[_assets[i]].fixedRateCap60dReceiveFixed,
                fixedRateCap90dPayFixed: _baseSpreads[_assets[i]].fixedRateCap90dPayFixed,
                fixedRateCap90dReceiveFixed: _baseSpreads[_assets[i]].fixedRateCap90dReceiveFixed
            });
        }

        proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeWithSignature(
                "initialize(address[],(uint256,uint256,uint256,uint256,uint256)[],(int256,int256,int256,int256,int256,int256,uint256,uint256,uint256,uint256,uint256,uint256)[])",
                _assets,
                riskIndicators,
                baseSpreadsAndFixedRateCaps
            )
        );
    }
}
