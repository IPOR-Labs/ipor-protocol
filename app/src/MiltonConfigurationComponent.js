import React from "react";
import { newContextComponents } from "@drizzle/react-components";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <div className="row">
            <table className="table" align="center">
                <tr>
                    <th scope="col">Parameter</th>
                    <th scope="col">
                        USDT
                        <br />
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        USDC
                        <br />
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        DAI
                        <br />
                        <br />
                        <br />
                    </th>
                </tr>

                <tr>
                    <td>
                        <strong>Asset Address</strong>
                        <small></small>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleMiltonUsdt"
                                method="getAsset"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleMiltonUsdc"
                                method="getAsset"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleMiltonDai"
                                method="getAsset"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Ipor Oracle Address</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdt"
                            method="getIporOracle"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdc"
                            method="getIporOracle"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonDai"
                            method="getIporOracle"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Milton Storage Address</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdt"
                            method="getMiltonStorage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdc"
                            method="getMiltonStorage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonDai"
                            method="getMiltonStorage"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Joseph Address</strong>
                        <small></small>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleMiltonUsdt"
                                method="getJoseph"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleMiltonUsdt"
                                method="setJoseph"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleMiltonUsdc"
                                method="getJoseph"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleMiltonUsdc"
                                method="setJoseph"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleMiltonDai"
                                method="getJoseph"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleMiltonDai"
                                method="setJoseph"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Stanley Address</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdt"
                            method="getStanley"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdc"
                            method="getStanley"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonDai"
                            method="getStanley"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Milton Spread Model Address</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdt"
                            method="getMiltonSpreadModel"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdc"
                            method="getMiltonSpreadModel"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonDai"
                            method="getMiltonSpreadModel"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Auto Upate Ipor Index Threshold</strong>
                        <br />
                        <small>
                            Notice! Don't use decimals. The value represents multiples of 1000.
                        </small>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleMiltonUsdt"
                                method="getAutoUpdateIporIndexThreshold"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleMiltonUsdt"
                                method="setAutoUpdateIporIndexThreshold"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleMiltonUsdc"
                                method="getAutoUpdateIporIndexThreshold"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleMiltonUsdc"
                                method="setAutoUpdateIporIndexThreshold"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleMiltonDai"
                                method="getAutoUpdateIporIndexThreshold"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleMiltonDai"
                                method="setAutoUpdateIporIndexThreshold"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Max Swap Total Amount</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdt"
                            method="getMaxSwapCollateralAmount"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdc"
                            method="getMaxSwapCollateralAmount"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonDai"
                            method="getMaxSwapCollateralAmount"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                </tr>
                <tr>
                    <td>
                        <strong>Max Liquidity Pool Utilization Rate</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdt"
                            method="getMaxLpUtilizationRate"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdc"
                            method="getMaxLpUtilizationRate"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonDai"
                            method="getMaxLpUtilizationRate"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Max Liquidity Pool Utilization Per Leg Rate</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdt"
                            method="getMaxLpUtilizationPerLegRate"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdc"
                            method="getMaxLpUtilizationPerLegRate"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonDai"
                            method="getMaxLpUtilizationPerLegRate"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Income Fee Rate</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdt"
                            method="getIncomeFeeRate"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdc"
                            method="getIncomeFeeRate"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonDai"
                            method="getIncomeFeeRate"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Opening Fee Rate</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdt"
                            method="getOpeningFeeRate"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdc"
                            method="getOpeningFeeRate"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonDai"
                            method="getOpeningFeeRate"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Opening Fee For Treasury Rate</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdt"
                            method="getOpeningFeeTreasuryPortionRate"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdc"
                            method="getOpeningFeeTreasuryPortionRate"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonDai"
                            method="getOpeningFeeTreasuryPortionRate"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>IPOR Publication Fee Amount</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdt"
                            method="getIporPublicationFee"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdc"
                            method="getIporPublicationFee"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonDai"
                            method="getIporPublicationFee"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Liquidation Deposit Amount</strong>
                        <br />
                        <small>Notice! Don't use decimals.</small>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdt"
                            method="getLiquidationDepositAmount"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdc"
                            method="getLiquidationDepositAmount"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonDai"
                            method="getLiquidationDepositAmount"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Max Leverage Value</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdt"
                            method="getMaxLeverage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdc"
                            method="getMaxLeverage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonDai"
                            method="getMaxLeverage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Min Leverage Value</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdt"
                            method="getMinLeverage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonUsdc"
                            method="getMinLeverage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleMiltonDai"
                            method="getMinLeverage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                </tr>
            </table>
        </div>
    </div>
);
