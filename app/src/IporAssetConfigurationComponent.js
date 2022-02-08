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
                        {drizzle.contracts.UsdtMockedToken.address}
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        USDC
                        <br />
                        {drizzle.contracts.UsdcMockedToken.address}
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        DAI
                        <br />
                        {drizzle.contracts.DaiMockedToken.address}
                        <br />
                        <br />
                    </th>
                </tr>
                <tr>
                    <td>
                        <br />
                        <strong>Ipor Configuration Address</strong>
                        <br />
                        <br />
                    </td>
                    <td>
                        <br />
                        {drizzle.contracts.IporAssetConfigurationUsdt.address}
                        <br />
                        <br />
                    </td>
                    <td>
                        <br />
                        {drizzle.contracts.IporAssetConfigurationUsdc.address}
                        <br />
                        <br />
                    </td>
                    <td>
                        <br />
                        {drizzle.contracts.IporAssetConfigurationDai.address}
                        <br />
                        <br />
                    </td>
                </tr>
                <tr>
                    <td>
                        <strong>IP Token Address</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getIpToken"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getIpToken"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getIpToken"
                        />
                    </td>
                </tr>
                <tr>
                    <td>
                        <strong>Milton</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getMilton"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setMilton"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getMilton"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setMilton"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getMilton"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setMilton"
                        />
                    </td>
                </tr>
                <tr>
                    <td>
                        <strong>Milton Storage</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getMiltonStorage"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setMiltonStorage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getMiltonStorage"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setMiltonStorage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getMiltonStorage"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setMiltonStorage"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Joseph</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getJoseph"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setJoseph"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getJoseph"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setJoseph"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getJoseph"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setJoseph"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Income Tax Percentage</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getIncomeTaxPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setIncomeTaxPercentage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getIncomeTaxPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setIncomeTaxPercentage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getIncomeTaxPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setIncomeTaxPercentage"
                        />
                    </td>
                </tr>
                <tr>
                    <td>
                        <strong>Liquidation Deposit Fee Amount</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getLiquidationDepositAmount"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />

                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setLiquidationDepositAmount"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getLiquidationDepositAmount"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setLiquidationDepositAmount"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getLiquidationDepositAmount"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setLiquidationDepositAmount"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Open Fee Percentage</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getOpeningFeePercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setOpeningFeePercentage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getOpeningFeePercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setOpeningFeePercentage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getOpeningFeePercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setOpeningFeePercentage"
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
                            contract="IporAssetConfigurationUsdt"
                            method="getIporPublicationFeeAmount"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setIporPublicationFeeAmount"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getIporPublicationFeeAmount"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setIporPublicationFeeAmount"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getIporPublicationFeeAmount"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setIporPublicationFeeAmount"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Minimum Collateralization Factor Value</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getMinCollateralizationFactorValue"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setMinCollateralizationFactorValue"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getMinCollateralizationFactorValue"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />

                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setMinCollateralizationFactorValue"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getMinCollateralizationFactorValue"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />

                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setMinCollateralizationFactorValue"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Maximum Collateralization Factor Value</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getMaxCollateralizationFactorValue"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setMaxCollateralizationFactorValue"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getMaxCollateralizationFactorValue"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setMaxCollateralizationFactorValue"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getMaxCollateralizationFactorValue"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setMaxCollateralizationFactorValue"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Opening Fee for Treasury Percentage</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getOpeningFeeForTreasuryPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setOpeningFeeForTreasuryPercentage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getOpeningFeeForTreasuryPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setOpeningFeeForTreasuryPercentage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getOpeningFeeForTreasuryPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setOpeningFeeForTreasuryPercentage"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>
                            Liquidity Pool Max Utilization Percentage
                        </strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getLiquidityPoolMaxUtilizationPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setLiquidityPoolMaxUtilizationPercentage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getLiquidityPoolMaxUtilizationPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setLiquidityPoolMaxUtilizationPercentage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getLiquidityPoolMaxUtilizationPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setLiquidityPoolMaxUtilizationPercentage"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>
                            Liquidity Pool Max Utilization Per Leg Percentage
                        </strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getLiquidityPoolMaxUtilizationPerLegPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setLiquidityPoolMaxUtilizationPerLegPercentage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getLiquidityPoolMaxUtilizationPerLegPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setLiquidityPoolMaxUtilizationPerLegPercentage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getLiquidityPoolMaxUtilizationPerLegPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setLiquidityPoolMaxUtilizationPerLegPercentage"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Charlie Treasuers</strong>
                        <br />
                        <small>Manage IPOR publication fee token balance</small>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getCharlieTreasurer"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setCharlieTreasurer"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getCharlieTreasurer"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setCharlieTreasurer"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getCharlieTreasurer"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setCharlieTreasurer"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Treasure Manager</strong>
                        <br />
                        <small>Manage opening fee balance</small>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getTreasureTreasurer"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setTreasureTreasurer"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getTreasureTreasurer"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setTreasureTreasurer"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getTreasureTreasurer"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setTreasureTreasurer"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Asset Management Vault</strong>
                        <br />
                        <small>
                            Manage LP balance in external portals like AAVE &
                            Compound
                        </small>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getAssetManagementVault"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setAssetManagementVault"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getAssetManagementVault"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setAssetManagementVault"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getAssetManagementVault"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setAssetManagementVault"
                        />
                    </td>
                </tr>
                <tr>
                    <td>
                        <strong>Grant role to user</strong>
                        <br />
                        <small>
                            In field role use byte32 representation. Available
                            roles listed below.
                        </small>
                    </td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="grantRole"
                        />
                    </td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="grantRole"
                        />
                    </td>
                    <td>
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="grantRole"
                        />
                    </td>
                </tr>
            </table>
            <table>
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Value</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>ADMIN_ROLE</td>
                        <td>
                            0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775
                        </td>
                    </tr>
                    <tr>
                        <td>MILTON_ADMIN_ROLE</td>
                        <td>
                            0x1b16f266cfe5113986bbdf79323bd64ba74c9e2631c82de1297c13405226a952
                        </td>
                    </tr>
                    <tr>
                        <td>MILTON_ROLE</td>
                        <td>
                            0x57a20741ae1ee76695a182cdfb995538919da5f1f6a92bca097f37a35c4be803
                        </td>
                    </tr>
                    <tr>
                        <td>MILTON_STORAGE_ADMIN_ROLE</td>
                        <td>
                            0x61e410eb94acd095b84b0de4a9befc42adb8e88aad1e0c387e8f14c5c05f4cd5
                        </td>
                    </tr>
                    <tr>
                        <td>MILTON_STORAGE_ROLE</td>
                        <td>
                            0xb8f71ab818f476672f61fd76955446cd0045ed8ddb51f595d9e262b68d1157f6
                        </td>
                    </tr>
                    <tr>
                        <td>JOSEPH_ADMIN_ROLE</td>
                        <td>
                            0x811ff4f923fc903f4390f8acf72873b5d1b288ec77b442fe124d0f95d6a53731
                        </td>
                    </tr>
                    <tr>
                        <td>JOSEPH_ROLE</td>
                        <td>
                            0x2c03e103fc464998235bd7f80967993a1e6052d41cc085d3317ca8e301f51125
                        </td>
                    </tr>

                    <tr>
                        <td>CHARLIE_TREASURER_ADMIN_ROLE</td>
                        <td>
                            0x0a8c46bed2194419383260fcc83e7085079a16a3dce173fb3d66eb1f81c71f6e
                        </td>
                    </tr>
                    <tr>
                        <td>CHARLIE_TREASURER_ROLE</td>
                        <td>
                            0x21b203ce7b3398e0ad35c938bc2c62a805ef17dc57de85e9d29052eac6d9d6f7
                        </td>
                    </tr>
                    <tr>
                        <td>TREASURE_TREASURER_ADMIN_ROLE</td>
                        <td>
                            0x1ba824e22ad2e0dc1d7a152742f3b5890d88c5a849ed8e57f4c9d84203d3ea9c
                        </td>
                    </tr>
                    <tr>
                        <td>TREASURE_TREASURER_ROLE</td>
                        <td>
                            0x9cdee4e06275597b667c73a5eb52ed89fe6acbbd36bd9fa38146b1316abfbbc4
                        </td>
                    </tr>
                    <tr>
                        <td>ASSET_MANAGEMENT_VAULT_ADMIN_ROLE</td>
                        <td>
                            0x1d3c5c61c32255cb922b09e735c0e9d76d2aacc424c3f7d9b9b85c478946fa26
                        </td>
                    </tr>
                    <tr>
                        <td>ASSET_MANAGEMENT_VAULT_ROLE</td>
                        <td>
                            0x2a7b2b7d358f8b11f783d1505af660b492b725a034776176adc7c268915d5bd8
                        </td>
                    </tr>
                    <tr>
                        <td>DECAY_FACTOR_VALUE_ADMIN_ROLE</td>
                        <td>
                            0xed044c57d37423bb4623f9110729ee31cae04cae931fe5ab3b24fc2e474fbb70
                        </td>
                    </tr>
                    <tr>
                        <td>DECAY_FACTOR_VALUE_ROLE</td>
                        <td>
                            0x94c58a89ab11d8b2894ecfbd6cb5c324f772536d0ea878a10cee7effe8ce98d0
                        </td>
                    </tr>
                    <tr>
                        <td>ROLES_INFO_ADMIN_ROLE</td>
                        <td>
                            0xfb1902cbac4bf447ada58dff398caab7aa9089eba1be77a2833d9e08dbe8664c
                        </td>
                    </tr>
                    <tr>
                        <td>ROLES_INFO_ROLE</td>
                        <td>
                            0xc878cde3567a457053651a2406e31db6dbb9207b6d5eedb081ef807beaaf5444
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
);
