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
            methodArgs={[drizzle.contracts.MockTestnetTokenUsdt.address, 0, 50]}
            render={DerivativeList}
        />
        <h5>Swaps Pay Fixed USDC</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="CockpitDataProvider"
            method="getMySwapsPayFixed"
            methodArgs={[drizzle.contracts.MockTestnetTokenUsdc.address, 0, 50]}
            render={DerivativeList}
        />
        <h5>Swaps Pay Fixed DAI</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="CockpitDataProvider"
            method="getMySwapsPayFixed"
            methodArgs={[drizzle.contracts.MockTestnetTokenDai.address, 0, 50]}
            render={DerivativeList}
        />
        <h5>Swaps Receive Fixed USDT</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="CockpitDataProvider"
            method="getMySwapsReceiveFixed"
            methodArgs={[drizzle.contracts.MockTestnetTokenUsdt.address, 0, 50]}
            render={DerivativeList}
        />
        <h5>Swaps Receive Fixed USDC</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="CockpitDataProvider"
            method="getMySwapsReceiveFixed"
            methodArgs={[drizzle.contracts.MockTestnetTokenUsdc.address, 0, 50]}
            render={DerivativeList}
        />
        <h5>Swaps Receive Fixed DAI</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="CockpitDataProvider"
            method="getMySwapsReceiveFixed"
            methodArgs={[drizzle.contracts.MockTestnetTokenDai.address, 0, 50]}
            render={DerivativeList}
        />
        <br />
    </div>
);
