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
            contract="CockpitDataProvider"
            method="getMySwapsPayFixed"
            methodArgs={[drizzle.contracts.DrizzleUsdt.address, 0, 50]}
            render={DerivativeList}
        />
        <h5>Swaps Pay Fixed USDC</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="CockpitDataProvider"
            method="getMySwapsPayFixed"
            methodArgs={[drizzle.contracts.DrizzleUsdc.address, 0, 50]}
            render={DerivativeList}
        />
        <h5>Swaps Pay Fixed DAI</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="CockpitDataProvider"
            method="getMySwapsPayFixed"
            methodArgs={[drizzle.contracts.DrizzleDai.address, 0, 50]}
            render={DerivativeList}
        />
        <h5>Swaps Receive Fixed USDT</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="CockpitDataProvider"
            method="getMySwapsReceiveFixed"
            methodArgs={[drizzle.contracts.DrizzleUsdt.address, 0, 50]}
            render={DerivativeList}
        />
        <h5>Swaps Receive Fixed USDC</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="CockpitDataProvider"
            method="getMySwapsReceiveFixed"
            methodArgs={[drizzle.contracts.DrizzleUsdc.address, 0, 50]}
            render={DerivativeList}
        />
        <h5>Swaps Receive Fixed DAI</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="CockpitDataProvider"
            method="getMySwapsReceiveFixed"
            methodArgs={[drizzle.contracts.DrizzleDai.address, 0, 50]}
            render={DerivativeList}
        />
        <br />
    </div>
);
