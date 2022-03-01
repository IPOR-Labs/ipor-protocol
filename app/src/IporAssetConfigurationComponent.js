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
                        <strong>Ipor Asset Configuration Address</strong>
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
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getMilton"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getMilton"
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
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getMiltonStorage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getMiltonStorage"
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
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getJoseph"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getJoseph"
                        />
                    </td>
                </tr>
            </table>
        </div>
    </div>
);
