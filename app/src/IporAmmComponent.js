import React from "react";
import {newContextComponents} from "@drizzle/react-components";
import DerivativeList from "./DerivativeList";
import AmmBalanceComponent from "./AmmBalanceComponent";

const {ContractData, ContractForm} = newContextComponents;

export default ({drizzle, drizzleState}) => (
    <div>
        <div>
            <br/>
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
                    <td><strong>AMM Balance of</strong></td>
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


            <AmmBalanceComponent
                drizzle={drizzle}
                drizzleState={drizzleState}
            />
        </div>
        <hr/>
        <div class="row">
            <div className="col-md-9">
                <strong>Open Position Form</strong>
                <ContractForm
                    drizzle={drizzle}
                    contract="IporAmmV1"
                    method="openPosition"/>
            </div>
            <div className="col-md-3">
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
            method="getOpenPositions"
            render={DerivativeList}
        />
        <hr/>

    </div>
);

