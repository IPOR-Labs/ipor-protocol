// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../../contracts/interfaces/IAmmSwapsLens.sol";
import "../../contracts/interfaces/IAmmGovernanceLens.sol";
import "../../contracts/interfaces/IAmmOpenSwapLens.sol";
import "../../contracts/interfaces/IAmmCloseSwapLens.sol";
import "../../contracts/interfaces/IAmmCloseSwapService.sol";
import "../../contracts/interfaces/IIporOracle.sol";
import "../../contracts/interfaces/types/IporTypes.sol";
import {console2} from "forge-std/console2.sol";

contract ItfHelper {
    struct OfferedRate {
        uint256 offeredRatePayFixed28;
        uint256 offeredRateReceiveFixed28;
        uint256 offeredRatePayFixed60;
        uint256 offeredRateReceiveFixed60;
        uint256 offeredRatePayFixed90;
        uint256 offeredRateReceiveFixed90;
    }

    struct AmmData {
        address asset;
        IAmmGovernanceLens.AmmPoolsParamsConfiguration ammPoolsParamsConfiguration;
        AmmTypes.OpenSwapRiskIndicators riskIndicatorsPayFixed28;
        AmmTypes.OpenSwapRiskIndicators riskIndicatorsPayFixed60;
        AmmTypes.OpenSwapRiskIndicators riskIndicatorsPayFixed90;
        AmmTypes.OpenSwapRiskIndicators riskIndicatorsReceiveFixed28;
        AmmTypes.OpenSwapRiskIndicators riskIndicatorsReceiveFixed60;
        AmmTypes.OpenSwapRiskIndicators riskIndicatorsReceiveFixed90;
        IAmmOpenSwapLens.AmmOpenSwapServicePoolConfiguration ammOpenSwapServicePoolConfiguration;
        OfferedRate offeredRate;
        Soap soap;
        Index index;
    }

    struct Soap {
        int256 soapPayFixed;
        int256 soapReceiveFixed;
        int256 soap;
    }

    struct Index {
        uint256 value;
        uint256 ibtPrice;
        uint256 lastUpdateTimestamp;
    }

    address internal immutable _router;
    address internal immutable _iporOracle;
    address internal immutable _usdt;
    address internal immutable _usdc;
    address internal immutable _dai;

    constructor(address router, address iporOracle, address usdt, address usdc, address dai) {
        _router = router;
        _iporOracle = iporOracle;
        _usdt = usdt;
        _usdc = usdc;
        _dai = dai;
    }

    function getRouter() external view returns (address) {
        return _router;
    }

    function getPnl(address account, address asset) external view returns (int256) {
        uint256 totalCount = 1;
        int256 pnl;
        uint256 offset;
        IAmmSwapsLens.IporSwap[] memory openSwaps;

        while (offset < totalCount) {
            (totalCount, openSwaps) = IAmmSwapsLens(_router).getSwaps(asset, account, offset, 50);
            if (totalCount == 0) {
                break;
            }
            offset += openSwaps.length;

            AmmTypes.ClosingSwapDetails memory swapDetails;
            for (uint i; i < openSwaps.length; ++i) {
                swapDetails = IAmmCloseSwapLens(_router).getClosingSwapDetails(
                    asset,
                    account,
                    AmmTypes.SwapDirection(openSwaps[i].direction),
                    openSwaps[i].id,
                    block.timestamp
                );
                pnl += swapDetails.pnlValue;
            }
        }
        return pnl;
    }

    function getAmmData(address asset) external view returns (AmmData memory) {
        AmmData memory ammData;
        OfferedRate memory offeredRate;
        Soap memory soap;
        Index memory index;
        ammData.asset = asset;
        ammData.ammPoolsParamsConfiguration = IAmmGovernanceLens(_router).getAmmPoolsParams(asset);
        ammData.riskIndicatorsPayFixed28 = IAmmSwapsLens(_router).getOpenSwapRiskIndicators(
            asset,
            0,
            IporTypes.SwapTenor.DAYS_28
        );
        ammData.riskIndicatorsPayFixed60 = IAmmSwapsLens(_router).getOpenSwapRiskIndicators(
            asset,
            0,
            IporTypes.SwapTenor.DAYS_60
        );
        ammData.riskIndicatorsPayFixed90 = IAmmSwapsLens(_router).getOpenSwapRiskIndicators(
            asset,
            0,
            IporTypes.SwapTenor.DAYS_90
        );
        ammData.riskIndicatorsReceiveFixed28 = IAmmSwapsLens(_router).getOpenSwapRiskIndicators(
            asset,
            1,
            IporTypes.SwapTenor.DAYS_28
        );
        ammData.riskIndicatorsReceiveFixed60 = IAmmSwapsLens(_router).getOpenSwapRiskIndicators(
            asset,
            1,
            IporTypes.SwapTenor.DAYS_60
        );
        ammData.riskIndicatorsReceiveFixed90 = IAmmSwapsLens(_router).getOpenSwapRiskIndicators(
            asset,
            1,
            IporTypes.SwapTenor.DAYS_90
        );
        ammData.ammOpenSwapServicePoolConfiguration = IAmmOpenSwapLens(_router).getAmmOpenSwapServicePoolConfiguration(
            asset
        );
        (offeredRate.offeredRatePayFixed28, offeredRate.offeredRateReceiveFixed28) = IAmmSwapsLens(_router)
            .getOfferedRate(asset, IporTypes.SwapTenor.DAYS_28, 100_000e18);
        (offeredRate.offeredRatePayFixed60, offeredRate.offeredRateReceiveFixed60) = IAmmSwapsLens(_router)
            .getOfferedRate(asset, IporTypes.SwapTenor.DAYS_60, 100_000e18);
        (offeredRate.offeredRatePayFixed90, offeredRate.offeredRateReceiveFixed90) = IAmmSwapsLens(_router)
            .getOfferedRate(asset, IporTypes.SwapTenor.DAYS_90, 100_000e18);
        (soap.soapPayFixed, soap.soapReceiveFixed, soap.soap) = IAmmSwapsLens(_router).getSoap(asset);
        (index.value, index.ibtPrice, index.lastUpdateTimestamp) = IIporOracle(_iporOracle).getIndex(asset);
        ammData.soap = soap;
        ammData.index = index;
        ammData.offeredRate = offeredRate;
        return ammData;
    }

    function liquidate(
        address asset,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds
    ) external returns (uint256[] memory) {
        uint256 payFixedSwapIdsLength = payFixedSwapIds.length;
        uint256 receiveFixedSwapIdsLength = receiveFixedSwapIds.length;
        uint256[] memory closed = new uint256[](payFixedSwapIdsLength + receiveFixedSwapIdsLength);
        uint256[] memory toClose = new uint256[](1);
        uint256[] memory empty = new uint256[](0);
        uint256 closeIndex = 0;

        if (asset == _dai) {
            for (uint256 i; i < payFixedSwapIdsLength; ++i) {
                toClose[0] = payFixedSwapIds[i];
                try IAmmCloseSwapService(_router).closeSwapsDai(address(this), toClose, empty) {
                    console2.log("closeSwapsDai success, id: ", payFixedSwapIds[i]);
                    closed[closeIndex] = payFixedSwapIds[i];
                    ++closeIndex;
                } catch Error(string memory reason) {
                    console2.log("closeSwapsDai failed, id: ", payFixedSwapIds[i]);
                } catch (bytes memory reason) {
                    console2.log("closeSwapsDai failed, id: ", payFixedSwapIds[i]);
                }
            }
            for (uint256 i; i < receiveFixedSwapIdsLength; ++i) {
                toClose[0] = receiveFixedSwapIds[i];
                try IAmmCloseSwapService(_router).closeSwapsDai(address(this), empty, toClose) {
                    console2.log("closeSwapsDai success, id: ", receiveFixedSwapIds[i]);
                    closed[closeIndex] = receiveFixedSwapIds[i];
                    ++closeIndex;
                } catch Error(string memory reason) {
                    console2.log("closeSwapsDai failed, id: ", receiveFixedSwapIds[i]);
                } catch (bytes memory reason) {
                    console2.log("closeSwapsDai failed, id: ", receiveFixedSwapIds[i]);
                }
            }
            return closed;
        } else if (asset == _usdc) {
            for (uint256 i; i < payFixedSwapIdsLength; ++i) {
                toClose[0] = payFixedSwapIds[i];
                try IAmmCloseSwapService(_router).closeSwapsUsdc(address(this), toClose, empty) {
                    console2.log("closeSwapsUsdc success, id: ", payFixedSwapIds[i]);
                    closed[closeIndex] = payFixedSwapIds[i];
                    ++closeIndex;
                } catch Error(string memory reason) {
                    console2.log("closeSwapsUsdc failed, id: ", payFixedSwapIds[i]);
                } catch (bytes memory reason) {
                    console2.log("closeSwapsUsdc failed, id: ", payFixedSwapIds[i]);
                }
            }
            for (uint256 i; i < receiveFixedSwapIdsLength; ++i) {
                toClose[0] = receiveFixedSwapIds[i];
                try IAmmCloseSwapService(_router).closeSwapsUsdc(address(this), empty, toClose) {
                    console2.log("closeSwapsUsdc success, id: ", receiveFixedSwapIds[i]);
                    closed[closeIndex] = receiveFixedSwapIds[i];
                    ++closeIndex;
                } catch Error(string memory reason) {
                    console2.log("closeSwapsUsdc failed, id: ", receiveFixedSwapIds[i]);
                } catch (bytes memory reason) {
                    console2.log("closeSwapsUsdc failed, id: ", receiveFixedSwapIds[i]);
                }
            }
            return closed;
        } else if (asset == _usdt) {
            for (uint256 i; i < payFixedSwapIdsLength; ++i) {
                toClose[0] = payFixedSwapIds[i];
                try IAmmCloseSwapService(_router).closeSwapsUsdt(address(this), toClose, empty) {
                    console2.log("closeSwapsUsdt success, id: ", payFixedSwapIds[i]);
                    closed[closeIndex] = payFixedSwapIds[i];
                    ++closeIndex;
                } catch Error(string memory reason) {
                    console2.log("closeSwapsUsdt failed, id: ", payFixedSwapIds[i]);
                } catch (bytes memory reason) {
                    console2.log("closeSwapsUsdt failed, id: ", payFixedSwapIds[i]);
                }
            }
            for (uint256 i; i < receiveFixedSwapIdsLength; ++i) {
                toClose[0] = receiveFixedSwapIds[i];
                try IAmmCloseSwapService(_router).closeSwapsUsdt(address(this), empty, toClose) {
                    console2.log("closeSwapsUsdt success, id: ", receiveFixedSwapIds[i]);
                    closed[closeIndex] = receiveFixedSwapIds[i];
                    ++closeIndex;
                } catch Error(string memory reason) {
                    console2.log("closeSwapsUsdt failed, id: ", receiveFixedSwapIds[i]);
                } catch (bytes memory reason) {
                    console2.log("closeSwapsUsdt failed, id: ", receiveFixedSwapIds[i]);
                }
            }
            return closed;
        }
    }

    function _closeDai(uint256[] memory payFixedSwapIds, uint256[] memory receiveFixedSwapIds) internal {}
}
