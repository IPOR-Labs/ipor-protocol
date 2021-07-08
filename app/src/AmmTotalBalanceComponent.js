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
            <td><strong>Token Address</strong></td>
            <td>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporAmmV1"
                    method="tokens"
                    methodArgs={["USDT"]}
                />
            </td>
            <td>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporAmmV1"
                    method="tokens"
                    methodArgs={["USDC"]}
                />
            </td>
            <td>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporAmmV1"
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
                    contract="IporAmmV1"
                    method="getTotalSupply"
                    methodArgs={["USDT"]}
                />
            </td>
            <td>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporAmmV1"
                    method="getTotalSupply"
                    methodArgs={["USDC"]}
                />
            </td>
            <td>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="IporAmmV1"
                    method="getTotalSupply"
                    methodArgs={["DAI"]}
                />
            </td>
        </tr>
    </table>
);