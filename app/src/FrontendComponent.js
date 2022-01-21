import React from "react";
import { newContextComponents } from "@drizzle/react-components";
import FrontendPositions from "./FrontendPositions";
import FrontendConfigurations from "./FrontendConfigurations";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div align="left">
        <table className="table">
            <tr>
                <th scope="col">Total Outstanding Notional</th>
                <th scope="col">
                    USDT
                    <br />
                    <small>{drizzle.contracts.UsdtMockedToken.address}</small>
                </th>
                <th scope="col">
                    USDC
                    <br />
                    <small>{drizzle.contracts.UsdcMockedToken.address}</small>
                </th>
                <th scope="col">
                    DAI
                    <br />
                    <small>{drizzle.contracts.DaiMockedToken.address}</small>
                </th>
            </tr>
            <tr>
                <td>Pay Fixed Total Notional</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFrontendDataProvider"
                        method="getTotalOutstandingNotional"
                        methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.payFixedTotalNotional /
                                    1000000000000000000}
                                <br />
                                <small>{value.payFixedTotalNotional}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFrontendDataProvider"
                        method="getTotalOutstandingNotional"
                        methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.payFixedTotalNotional /
                                    1000000000000000000}
                                <br />
                                <small>{value.payFixedTotalNotional}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFrontendDataProvider"
                        method="getTotalOutstandingNotional"
                        methodArgs={[drizzle.contracts.DaiMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.payFixedTotalNotional /
                                    1000000000000000000}
                                <br />
                                <small>{value.payFixedTotalNotional}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>Receive Fixed Total Notional</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFrontendDataProvider"
                        method="getTotalOutstandingNotional"
                        methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.recFixedTotalNotional /
                                    1000000000000000000}
                                <br />
                                <small>{value.recFixedTotalNotional}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFrontendDataProvider"
                        method="getTotalOutstandingNotional"
                        methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.recFixedTotalNotional /
                                    1000000000000000000}
                                <br />
                                <small>{value.recFixedTotalNotional}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFrontendDataProvider"
                        method="getTotalOutstandingNotional"
                        methodArgs={[drizzle.contracts.DaiMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value.recFixedTotalNotional /
                                    1000000000000000000}
                                <br />
                                <small>{value.recFixedTotalNotional}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>ipToken Exchange Rate</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFrontendDataProvider"
                        method="getIpTokenExchangeRate"
                        methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
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
                        contract="MiltonFrontendDataProvider"
                        method="getIpTokenExchangeRate"
                        methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
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
                        contract="MiltonFrontendDataProvider"
                        method="getIpTokenExchangeRate"
                        methodArgs={[drizzle.contracts.DaiMockedToken.address]}
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
        <hr />
        <h5>Frontend Configuration</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="MiltonFrontendDataProvider"
            method="getConfiguration"
            render={FrontendConfigurations}
        />
        <hr />
        <h5>My Positions</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="MiltonFrontendDataProvider"
            method="getMySwaps"
            render={FrontendPositions}
        />
    </div>
);
