import React from "react";
import {newContextComponents} from "@drizzle/react-components";

const {ContractData} = newContextComponents;

export default ({drizzle, drizzleState}) => (
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
                    contract="MiltonV1"
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
                    contract="MiltonV1"
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
                    contract="MiltonV1"
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
        <tr>
            <td><strong>My Total Balance</strong></td>
            <td>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="MiltonV1"
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
                    contract="MiltonV1"
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
                    contract="MiltonV1"
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
);