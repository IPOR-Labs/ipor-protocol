import React from "react";
import {newContextComponents} from "@drizzle/react-components";

const {ContractData, ContractForm} = newContextComponents;

export default ({drizzle, drizzleState}) => (
    <div align="left">
        <table className="table">
            <tr>
                <th scope="col">Total Outstanding Notional</th>
                <th scope="col">USDT</th>
                <th scope="col">USDC</th>
                <th scope="col">DAI</th>
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
                                {value.payFixedTotalNotional / 1000000000000000000}<br/>
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
                                {value.payFixedTotalNotional / 1000000000000000000}<br/>
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
                                {value.payFixedTotalNotional / 1000000000000000000}<br/>
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
                                {value.recFixedTotalNotional / 1000000000000000000}<br/>
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
                                {value.recFixedTotalNotional / 1000000000000000000}<br/>
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
                                {value.recFixedTotalNotional / 1000000000000000000}<br/>
                                <small>{value.recFixedTotalNotional}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
        </table>
    </div>
);
