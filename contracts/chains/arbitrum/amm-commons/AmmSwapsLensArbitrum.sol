// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Address.sol";
import "../../../interfaces/IAmmSwapsLens.sol";
import "../../../base/amm/libraries/AmmSwapsLensLibBaseV1.sol";
import "../../../libraries/IporContractValidator.sol";
import "../../../libraries/RiskIndicatorsValidatorLib.sol";
import "../../../libraries/AmmLib.sol";

/// @dev It is not recommended to use lens contract directly, should be used only through IporProtocolRouter.
contract AmmSwapsLensArbitrum is IAmmSwapsLens {
    using Address for address;
    using IporContractValidator for address;
    using AmmLib for AmmTypes.AmmPoolCoreModel;
    using RiskIndicatorsValidatorLib for AmmTypes.RiskIndicatorsInputs;

    address internal immutable _wstEthAsset;
    address internal immutable _wstEthAmmStorage;
    address internal immutable _wstEthAmmTreasury;
    address internal immutable _wstEthSpread;

    address public immutable iporOracle;
    address public immutable messageSigner;

    constructor(SwapLensPoolConfiguration memory wstEthCfg, address iporOracleInput, address messageSignerInput) {
        _wstEthAsset = wstEthCfg.asset.checkAddress();
        _wstEthAmmStorage = wstEthCfg.ammStorage.checkAddress();
        _wstEthAmmTreasury = wstEthCfg.ammTreasury.checkAddress();
        _wstEthSpread = wstEthCfg.spread.checkAddress();

        iporOracle = iporOracleInput.checkAddress();
        messageSigner = messageSignerInput.checkAddress();
    }

    function getSwapLensPoolConfiguration(
        address asset
    ) external view override returns (SwapLensPoolConfiguration memory) {
        return _getSwapLensPoolConfiguration(asset);
    }

    function getSwaps(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IAmmSwapsLens.IporSwap[] memory swaps) {
        return AmmSwapsLensLibBaseV1.getSwaps(iporOracle, _wstEthAmmStorage, asset, account, offset, chunkSize);
    }

    function getPnlPayFixed(address asset, uint256 swapId) external view override returns (int256) {
        return AmmSwapsLensLibBaseV1.getPnlPayFixed(iporOracle, _wstEthAmmStorage, _wstEthAsset, swapId);
    }

    function getPnlReceiveFixed(address asset, uint256 swapId) external view override returns (int256) {
        return AmmSwapsLensLibBaseV1.getPnlReceiveFixed(iporOracle, _wstEthAmmStorage, _wstEthAsset, swapId);
    }

    function getSoap(
        address asset
    ) external view override returns (int256 soapPayFixed, int256 soapReceiveFixed, int256 soap) {
        AmmTypes.AmmPoolCoreModel memory ammCoreModel;
        ammCoreModel.asset = asset;
        ammCoreModel.ammStorage = _wstEthAmmStorage;
        ammCoreModel.iporOracle = iporOracle;
        (soapPayFixed, soapReceiveFixed, soap) = ammCoreModel.getSoap();
    }

    function getOfferedRate(
        address asset,
        IporTypes.SwapTenor tenor,
        uint256 notional,
        AmmTypes.RiskIndicatorsInputs calldata payFixedRiskIndicatorsInputs,
        AmmTypes.RiskIndicatorsInputs calldata receiveFixedRiskIndicatorsInputs
    ) external view override returns (uint256 offeredRatePayFixed, uint256 offeredRateReceiveFixed) {
        require(notional > 0, AmmErrors.INVALID_NOTIONAL);

        SwapLensPoolConfiguration memory poolCfg = _getSwapLensPoolConfiguration(asset);

        (uint256 indexValue, , ) = IIporOracle(iporOracle).getIndex(asset);

        AmmTypes.OpenSwapRiskIndicators memory swapRiskIndicatorsPayFixed = payFixedRiskIndicatorsInputs.verify(
            asset,
            uint256(tenor),
            uint256(AmmTypes.SwapDirection.PAY_FIXED_RECEIVE_FLOATING),
            messageSigner
        );

        AmmTypes.OpenSwapRiskIndicators memory swapRiskIndicatorsReceiveFixed = receiveFixedRiskIndicatorsInputs.verify(
            asset,
            uint256(tenor),
            uint256(AmmTypes.SwapDirection.PAY_FLOATING_RECEIVE_FIXED),
            messageSigner
        );

        (offeredRatePayFixed, offeredRateReceiveFixed) = AmmSwapsLensLibBaseV1.getOfferedRate(
            poolCfg,
            indexValue,
            tenor,
            notional,
            messageSigner,
            swapRiskIndicatorsPayFixed,
            swapRiskIndicatorsReceiveFixed
        );
    }

    function getBalancesForOpenSwap(address) external view returns (IporTypes.AmmBalancesForOpenSwapMemory memory) {
        return AmmSwapsLensLibBaseV1.getBalancesForOpenSwap(_wstEthAmmStorage, _wstEthAmmTreasury);
    }

    function _getSwapLensPoolConfiguration(address asset) internal view returns (SwapLensPoolConfiguration memory) {
        if (asset == _wstEthAsset) {
            return
                SwapLensPoolConfiguration({
                    asset: _wstEthAsset,
                    ammStorage: _wstEthAmmStorage,
                    ammTreasury: _wstEthAmmTreasury,
                    spread: _wstEthSpread
                });
        } else {
            revert(IporErrors.ASSET_NOT_SUPPORTED);
        }
    }
}
