import React from "react";
import {newContextComponents} from "@drizzle/react-components";


const {ContractData, ContractForm} = newContextComponents;

export default ({drizzle, drizzleState}) => (
    <div>
        <table className="table" align="center">
            <tr>
                <th scope="col"></th>
                <th scope="col">USDT</th>
                <th scope="col">USDC</th>
                <th scope="col">DAI</th>
            </tr>
            <tr>
                <td><strong>ERC20 Token Address</strong></td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonV1"
                        method="tokens"
                        methodArgs={["USDT"]}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonV1"
                        method="tokens"
                        methodArgs={["USDC"]}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonV1"
                        method="tokens"
                        methodArgs={["DAI"]}
                    />
                </td>
            </tr>
            <tr>
                <td><strong>AMM Total Balance</strong></td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonDevToolDataProvider"
                        method="getTotalSupply"
                        methodArgs={["USDT"]}
                        render={(value) => (
                            <div>
                                {value / 1000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonDevToolDataProvider"
                        method="getTotalSupply"
                        methodArgs={["USDC"]}
                        render={(value) => (
                            <div>
                                {value / 1000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonDevToolDataProvider"
                        method="getTotalSupply"
                        methodArgs={["DAI"]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
        </table>
        <hr/>
        <table className="table" align="center">
            <tr>
                <th scope="col"></th>
                <th scope="col">USDT</th>
                <th scope="col">USDC</th>
                <th scope="col">DAI</th>
            </tr>
            <tr>
                <td><strong>My allowance for Milton</strong></td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonDevToolDataProvider"
                        method="getMyAllowance"
                        methodArgs={["USDT"]}
                        render={(value) => (
                            <div>
                                {value / 1000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />

                    Milton Address: <strong>{drizzle.contracts.MiltonV1.address}</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="UsdtMockedToken"
                        method="approve"
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonDevToolDataProvider"
                        method="getMyAllowance"
                        methodArgs={["USDC"]}
                        render={(value) => (
                            <div>
                                {value / 1000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />

                    Milton Address: <strong>{drizzle.contracts.MiltonV1.address}</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="UsdcMockedToken"
                        method="approve"
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonDevToolDataProvider"
                        method="getMyAllowance"
                        methodArgs={["DAI"]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />

                    Milton Address: <strong>{drizzle.contracts.MiltonV1.address}</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="DaiMockedToken"
                        method="approve"
                    />
                </td>
            </tr>
        </table>
        <hr/>
        <table className="table" align="center">
            <tr>
                <th scope="col"></th>
                <th scope="col">USDT</th>
                <th scope="col">USDC</th>
                <th scope="col">DAI</th>
            </tr>
            <tr>
                <td><strong>My Total Balance</strong></td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonDevToolDataProvider"
                        method="getMyTotalSupply"
                        methodArgs={["USDT"]}
                        render={(value) => (
                            <div>
                                {value / 1000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonDevToolDataProvider"
                        method="getMyTotalSupply"
                        methodArgs={["USDC"]}
                        render={(value) => (
                            <div>
                                {value / 1000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonDevToolDataProvider"
                        method="getMyTotalSupply"
                        methodArgs={["DAI"]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
        </table>
        <hr/>
    </div>
);