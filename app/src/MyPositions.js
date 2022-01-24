import React from "react";
import { newContextComponents } from "@drizzle/react-components";
import DerivativeList from "./DerivativeList";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <h5>Swaps Pay Fixed USDT</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="MiltonDevToolDataProvider"
            method="getMySwapsPayFixed"
            methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
            render={DerivativeList}
        />
        <h5>Swaps Pay Fixed USDC</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="MiltonDevToolDataProvider"
            method="getMySwapsPayFixed"
            methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
            render={DerivativeList}
        />
        <h5>Swaps Pay Fixed DAI</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="MiltonDevToolDataProvider"
            method="getMySwapsPayFixed"
            methodArgs={[drizzle.contracts.DaiMockedToken.address]}
            render={DerivativeList}
        />
        <h5>Swaps Receive Fixed USDT</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="MiltonDevToolDataProvider"
            method="getMySwapsReceiveFixed"
            methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
            render={DerivativeList}
        />
        <h5>Swaps Receive Fixed USDC</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="MiltonDevToolDataProvider"
            method="getMySwapsReceiveFixed"
            methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
            render={DerivativeList}
        />
        <h5>Swaps Receive Fixed DAI</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="MiltonDevToolDataProvider"
            method="getMySwapsReceiveFixed"
            methodArgs={[drizzle.contracts.DaiMockedToken.address]}
            render={DerivativeList}
        />
        <br />
    </div>
);
