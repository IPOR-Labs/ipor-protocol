import React from "react";
import { newContextComponents } from "@drizzle/react-components";
import DerivativeList from "./DerivativeList";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="MiltonDevToolDataProvider"
            method="getMySwaps"
            render={DerivativeList}
        />
    </div>
);
