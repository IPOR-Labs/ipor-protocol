import React from "react";
import {newContextComponents} from "@drizzle/react-components";
import ParseBigInt from "./ParseBigInt";

const {ContractData} = newContextComponents;

export default ({drizzle, drizzleState}) => (
    <div className="section">
        <table className="table" align="center">
            <tr>
                <th scope="col">Balance</th>
                <th scope="col">USDT</th>
                <th scope="col">USDC</th>
                <th scope="col">DAI</th>
            </tr>
            <tr>
                <td>Derivatives</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="derivativesTotalBalances"
                        methodArgs={["USDT"]}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="derivativesTotalBalances"
                        methodArgs={["USDC"]}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="derivativesTotalBalances"
                        methodArgs={["DAI"]}
                    />
                </td>
            </tr>
            <tr>
                <td>Liquidity Pool</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="liquidityPoolTotalBalances"
                        methodArgs={["USDT"]}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="liquidityPoolTotalBalances"
                        methodArgs={["USDC"]}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="liquidityPoolTotalBalances"
                        methodArgs={["DAI"]}
                    />
                </td>
            </tr>
            <tr>
                <td>Opening Fee</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="openingFeeTotalBalances"
                        methodArgs={["USDT"]}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="openingFeeTotalBalances"
                        methodArgs={["USDC"]}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="openingFeeTotalBalances"
                        methodArgs={["DAI"]}
                    />
                </td>
            </tr>
            <tr>
                <td>Liquidation Deposit Fee</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="liquidationDepositFeeTotalBalances"
                        methodArgs={["USDT"]}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="liquidationDepositFeeTotalBalances"
                        methodArgs={["USDC"]}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="liquidationDepositFeeTotalBalances"
                        methodArgs={["DAI"]}

                    />
                </td>
            </tr>
            <tr>
                <td>Ipor Publication Fee</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="iporPublicationFeeTotalBalances"
                        methodArgs={["USDT"]}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="iporPublicationFeeTotalBalances"
                        methodArgs={["USDC"]}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="iporPublicationFeeTotalBalances"
                        methodArgs={["DAI"]}
                    />
                </td>
            </tr>
        </table>
    </div>
);
