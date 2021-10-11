import React from "react";
import {newContextComponents} from "@drizzle/react-components";
import SpreadComponent from "./SpreadComponent";
import SoapComponent from "./SoapComponent";
import DaiMockedToken from "./contracts/DaiMockedToken.json";
import UsdcMockedToken from "./contracts/UsdcMockedToken.json";
import Joseph from "./contracts/Joseph.json";

const {ContractData} = newContextComponents;

export default ({drizzle, drizzleState}) => (
    <div className="section">


        <table className="table" align="center">
            <tr>
                <th scope="col">Exchange Rate</th>
                <th scope="col">USDT</th>
                <th scope="col">USDC</th>
                <th scope="col">DAI</th>
            </tr>
            <tr>
                <td></td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="Joseph"
                        method="calculateExchangeRate"
                        methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="Joseph"
                        method="calculateExchangeRate"
                        methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="Joseph"
                        method="calculateExchangeRate"
                        methodArgs={[drizzle.contracts.DaiMockedToken.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}<br/>
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
        </table>
    </div>
);
