import React from "react";
import {newContextComponents} from "@drizzle/react-components";

const {ContractData, ContractForm} = newContextComponents;

export default ({drizzle, drizzleState}) => (
    <div>
        <div className="row">
            <table className="table" align="center">
                <tr>
                    <th scope="col">Parameter</th>
                    <th scope="col">
                        USDT
                        <br/>
                        {drizzle.contracts.UsdtMockedToken.address}
                        <br/><br/>
                    </th>
                    <th scope="col">
                        USDC
                        <br/>
                        {drizzle.contracts.UsdcMockedToken.address}
                        <br/><br/>
                    </th>
                    <th scope="col">
                        DAI
                        <br/>
                        {drizzle.contracts.DaiMockedToken.address}
                        <br/><br/>
                    </th>
                </tr>
                <tr>
                    <td>
                        <br/>
                        <strong>Ipor Configuration Address</strong>
                        <br/><br/>
                    </td>
                    <td>
                        <br/>
                        {drizzle.contracts.IporAssetConfigurationUsdt.address}
                        <br/><br/>
                    </td>
                    <td>
                        <br/>
                        {drizzle.contracts.IporAssetConfigurationUsdc.address}
                        <br/><br/>
                    </td>
                    <td>
                        <br/>
                        {drizzle.contracts.IporAssetConfigurationDai.address}
                        <br/><br/>
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
                                    {value / 1000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setIncomeTaxPercentage"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getIncomeTaxPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setIncomeTaxPercentage"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getIncomeTaxPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setIncomeTaxPercentage"/>
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
                                    {value / 1000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />

                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setLiquidationDepositAmount"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getLiquidationDepositAmount"
                            render={(value) => (
                                <div>
                                    {value / 1000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setLiquidationDepositAmount"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getLiquidationDepositAmount"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setLiquidationDepositAmount"/>
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
                                    {value / 1000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setOpeningFeePercentage"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getOpeningFeePercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setOpeningFeePercentage"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getOpeningFeePercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setOpeningFeePercentage"/>
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
                                    {value / 1000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setIporPublicationFeeAmount"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getIporPublicationFeeAmount"
                            render={(value) => (
                                <div>
                                    {value / 1000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setIporPublicationFeeAmount"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getIporPublicationFeeAmount"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setIporPublicationFeeAmount"/>
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
                                    {value / 1000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setMinCollateralizationFactorValue"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getMinCollateralizationFactorValue"
                            render={(value) => (
                                <div>
                                    {value / 1000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />

                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setMinCollateralizationFactorValue"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getMinCollateralizationFactorValue"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />

                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setMinCollateralizationFactorValue"/>
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
                                    {value / 1000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setMaxCollateralizationFactorValue"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getMaxCollateralizationFactorValue"
                            render={(value) => (
                                <div>
                                    {value / 1000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setMaxCollateralizationFactorValue"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getMaxCollateralizationFactorValue"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setMaxCollateralizationFactorValue"/>
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
                                    {value / 1000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setOpeningFeeForTreasuryPercentage"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getOpeningFeeForTreasuryPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setOpeningFeeForTreasuryPercentage"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getOpeningFeeForTreasuryPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setOpeningFeeForTreasuryPercentage"/>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Liquidity Pool Max Utilization Percentage</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getLiquidityPoolMaxUtilizationPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setLiquidityPoolMaxUtilizationPercentage"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getLiquidityPoolMaxUtilizationPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setLiquidityPoolMaxUtilizationPercentage"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getLiquidityPoolMaxUtilizationPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}<br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setLiquidityPoolMaxUtilizationPercentage"/>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Charlie Treasuers</strong>
                        <br/>
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
                            method="setCharlieTreasurer"/>
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
                            method="setCharlieTreasurer"/>
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
                            method="setCharlieTreasurer"/>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Treasure Manager</strong>
                        <br/>
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
                            method="setTreasureTreasurer"/>
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
                            method="setTreasureTreasurer"/>
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
                            method="setTreasureTreasurer"/>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Asset Management Vault</strong>
                        <br/>
                        <small>Manage LP balance in external portals like AAVE & Compound</small>
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
                            method="setAssetManagementVault"/>
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
                            method="setAssetManagementVault"/>
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
                            method="setAssetManagementVault"/>
                    </td>
                </tr>

            </table>
        </div>
    </div>
);