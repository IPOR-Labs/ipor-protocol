import React from "react";
import {newContextComponents} from "@drizzle/react-components";
import DerivativeList from "./DerivativeList";
import AmmBalanceComponent from "./AmmBalanceComponent";
import AmmTotalBalanceComponent from "./AmmTotalBalanceComponent";
import LiquidityPoolComponent from "./LiquidityPoolComponent";

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
            <LiquidityPoolComponent
                drizzle={drizzle}
                drizzleState={drizzleState}
            />
        </div>
        <hr/>
        <div class="row">
            {process.env.REACT_APP_PRIV_TEST_NETWORK_USE_TEST_MILTON === "true" ?
                <div className="col-md-12">
                    <strong>Open Position Form (TestMilton)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="TestMilton"
                        method="openPosition"/>
                </div>
                :
                <div className="col-md-12">
                    <strong>Open Position Form (Milton)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="Milton"
                        method="openPosition"/>
                </div>
            }
        </div>
        <hr/>
        <div class="row">
            {process.env.REACT_APP_PRIV_TEST_NETWORK_USE_TEST_JOSEPH === "true" ?
                <div className="col-md-4">
                    <strong>Provide Liquidity (TestJoseph)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="TestJoseph"
                        method="provideLiquidity"/>
                </div>
                :
                <div className="col-md-4">
                    <strong>Provide Liquidity (Joseph)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="Joseph"
                        method="provideLiquidity"/>
                </div>
            }
            {process.env.REACT_APP_PRIV_TEST_NETWORK_USE_TEST_JOSEPH === "true" ?
                <div className="col-md-4">
                    <strong>Redeem (TestJoseph)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="TestJoseph"
                        method="redeem"/>
                </div>
                :
                <div className="col-md-4">
                    <strong>Redeem (Joseph)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="Joseph"
                        method="redeem"/>
                </div>
            }
            {process.env.REACT_APP_PRIV_TEST_NETWORK_USE_TEST_MILTON === "true" ?
                <div className="col-md-4">
                    <strong>Close Position Form (TestMilton)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="TestMilton"
                        method="closePosition"/>
                </div>
                :
                <div className="col-md-4">
                    <strong>Close Position Form (Milton)</strong>
                    <ContractForm
                        drizzle={drizzle}
                        contract="Milton"
                        method="closePosition"/>
                </div>
            }
        </div>

        <hr/>
        <h4>
            Open positions
        </h4>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="MiltonStorage"
            method="getPositions"
            render={DerivativeList}
        />
        <hr/>

    </div>
);
