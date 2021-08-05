import React from "react";
import {newContextComponents} from "@drizzle/react-components";
import DerivativeList from "./DerivativeList";
import AmmBalanceComponent from "./AmmBalanceComponent";
import AmmTotalBalanceComponent from "./AmmTotalBalanceComponent";

const {ContractData, ContractForm} = newContextComponents;

export default ({drizzle, drizzleState}) => (
    <div>
        <div>
            <br/>
            <AmmTotalBalanceComponent
                drizzle={drizzle}
                drizzleState={drizzleState}
            />
            <AmmBalanceComponent
                drizzle={drizzle}
                drizzleState={drizzleState}
            />
        </div>
        <hr/>
        <div class="row">
            <div className="col-md-12">
                <strong>Open Position Form</strong>
                <ContractForm
                    drizzle={drizzle}
                    contract="IporAmmV1"
                    method="openPosition"/>
            </div>
        </div>
        <hr/>
        <div class="row">
            <div className="col-md-7">
                <strong>Provide Liquidity</strong>
                <ContractForm
                    drizzle={drizzle}
                    contract="IporAmmV1"
                    method="provideLiquidity"/>
            </div>
            <div className="col-md-5">
                <strong>Close Position Form</strong>
                <ContractForm
                    drizzle={drizzle}
                    contract="IporAmmV1"
                    method="closePosition"/>
            </div>
        </div>

        <hr/>
        <h4>
            Open positions
        </h4>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="IporAmmV1"
            method="getPositions"
            render={DerivativeList}
        />
        <hr/>

    </div>
);
