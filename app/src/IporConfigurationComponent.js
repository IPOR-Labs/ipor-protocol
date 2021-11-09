import React from "react";
import {newContextComponents} from "@drizzle/react-components";
import IporConfigurationUsdc from "./contracts/IporConfigurationUsdc.json";

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
                        {drizzle.contracts.IporConfigurationUsdt.address}
                        <br/><br/>
                    </td>
                    <td>
                        <br/>
                        {drizzle.contracts.IporConfigurationUsdc.address}
                        <br/><br/>
                    </td>
                    <td>
                        <br/>
                        {drizzle.contracts.IporConfigurationDai.address}
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
                            contract="IporConfigurationUsdt"
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
                            contract="IporConfigurationUsdt"
                            method="setIncomeTaxPercentage"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporConfigurationUsdc"
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
                            contract="IporConfigurationUsdc"
                            method="setIncomeTaxPercentage"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporConfigurationDai"
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
                            contract="IporConfigurationDai"
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
                            contract="IporConfigurationUsdt"
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
                            contract="IporConfigurationUsdt"
                            method="setLiquidationDepositAmount"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporConfigurationUsdc"
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
                            contract="IporConfigurationUsdc"
                            method="setLiquidationDepositAmount"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporConfigurationDai"
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
                            contract="IporConfigurationDai"
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
                            contract="IporConfigurationUsdt"
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
                            contract="IporConfigurationUsdt"
                            method="setOpeningFeePercentage"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporConfigurationUsdc"
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
                            contract="IporConfigurationUsdc"
                            method="setOpeningFeePercentage"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporConfigurationDai"
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
                            contract="IporConfigurationDai"
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
                            contract="IporConfigurationUsdt"
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
                            contract="IporConfigurationUsdt"
                            method="setIporPublicationFeeAmount"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporConfigurationUsdc"
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
                            contract="IporConfigurationUsdc"
                            method="setIporPublicationFeeAmount"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporConfigurationDai"
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
                            contract="IporConfigurationDai"
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
                            contract="IporConfigurationUsdt"
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
                            contract="IporConfigurationUsdt"
                            method="setMinCollateralizationFactorValue"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporConfigurationUsdc"
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
                            contract="IporConfigurationUsdc"
                            method="setMinCollateralizationFactorValue"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporConfigurationDai"
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
                            contract="IporConfigurationDai"
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
                            contract="IporConfigurationUsdt"
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
                            contract="IporConfigurationUsdt"
                            method="setMaxCollateralizationFactorValue"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporConfigurationUsdc"
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
                            contract="IporConfigurationUsdc"
                            method="setMaxCollateralizationFactorValue"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporConfigurationDai"
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
                            contract="IporConfigurationDai"
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
                            contract="IporConfigurationUsdt"
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
                            contract="IporConfigurationUsdt"
                            method="setOpeningFeeForTreasuryPercentage"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporConfigurationUsdc"
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
                            contract="IporConfigurationUsdc"
                            method="setOpeningFeeForTreasuryPercentage"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporConfigurationDai"
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
                            contract="IporConfigurationDai"
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
                            contract="IporConfigurationUsdt"
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
                            contract="IporConfigurationUsdt"
                            method="setLiquidityPoolMaxUtilizationPercentage"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporConfigurationUsdc"
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
                            contract="IporConfigurationUsdc"
                            method="setLiquidityPoolMaxUtilizationPercentage"/>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporConfigurationDai"
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
                            contract="IporConfigurationDai"
                            method="setLiquidityPoolMaxUtilizationPercentage"/>
                    </td>
                </tr>

            </table>
        </div>
        <hr/>

        <div className="row">
            <table className="table" align="center">
                <tr>
                    <th scope="col">Name of treasuers</th>
                    <th scope="col">
                        USDT
                        <br/>
                        {drizzle.contracts.UsdtMockedToken.address}
                    </th>
                    <th scope="col">
                        USDC
                        <br/>
                        {drizzle.contracts.UsdcMockedToken.address}
                    </th>
                    <th scope="col">
                        DAI
                        <br/>
                        {drizzle.contracts.DaiMockedToken.address}
                    </th>
                </tr>
                <tr>
                    <td>
                        <strong>Charlie Treasuers</strong>
                        <br/>
                        <small>Manage IPOR publication fee balance</small>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAddressesManager"
                            method="getCharlieTreasurer"
                            methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAddressesManager"
                            method="getCharlieTreasurer"
                            methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAddressesManager"
                            method="getCharlieTreasurer"
                            methodArgs={[drizzle.contracts.DaiMockedToken.address]}
                        />
                    </td>
                </tr>
                <tr>
                    <td>
                        <strong>Treasure Treasuers</strong>
                        <br/>
                        <small>Manage opening fee balance</small>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAddressesManager"
                            method="getTreasureTreasurer"
                            methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAddressesManager"
                            method="getTreasureTreasurer"
                            methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAddressesManager"
                            method="getTreasureTreasurer"
                            methodArgs={[drizzle.contracts.DaiMockedToken.address]}
                        />
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
                            contract="IporAddressesManager"
                            method="getAssetManagementVault"
                            methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAddressesManager"
                            method="getAssetManagementVault"
                            methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAddressesManager"
                            method="getAssetManagementVault"
                            methodArgs={[drizzle.contracts.DaiMockedToken.address]}
                        />
                    </td>
                </tr>
            </table>
        </div>
        <div className="row">
            <div className="col-md-4">
                <strong>Charlie Treasuers</strong>
                <ContractForm
                    drizzle={drizzle}
                    contract="IporAddressesManager"
                    method="setCharlieTreasurer"/>
            </div>
            <div className="col-md-4">
                <strong>Treasure Treasuers</strong>
                <ContractForm
                    drizzle={drizzle}
                    contract="IporAddressesManager"
                    method="setTreasureTreasurer"/>
            </div>
            <div className="col-md-4">
                <strong>Asset Management Vault</strong>
                <ContractForm
                    drizzle={drizzle}
                    contract="IporAddressesManager"
                    method="setAssetManagementVault"/>
            </div>
        </div>
    </div>
);