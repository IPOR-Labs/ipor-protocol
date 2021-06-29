import React from "react";
import {newContextComponents} from "@drizzle/react-components";
import DerivativeList from "./DerivativeList";

const {ContractData, ContractForm} = newContextComponents;

export default ({drizzle, drizzleState}) => (
    <div>
        <h2>IPOR AMM</h2>
        <table align="center">
            <tr>
                <td>
                    <strong>POOL USDT</strong>
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="pools"
                        methodArgs={["USDT"]}
                    />
                </td>
            </tr>
            <tr>
                <td>
                    <strong>POOL USDC</strong>
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="pools"
                        methodArgs={["USDC"]}
                    />
                </td>
            </tr>
            <tr>
                <td>
                    <strong>POOL DAI</strong>
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="IporAmmV1"
                        method="pools"
                        methodArgs={["DAI"]}
                    />
                </td>
            </tr>
        </table>
        <hr/>

        <strong>Open Position Form</strong>
        <ContractForm
            drizzle={drizzle}
            contract="IporAmmV1"
            method="openPosition"/>
        <hr/>
        <strong>
            Open positions
        </strong>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="IporAmmV1"
            method="getOpenPositions"
            render={DerivativeList}
        />
        <hr/>
    </div>
);

