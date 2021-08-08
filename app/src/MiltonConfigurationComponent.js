import React from "react";
import {newContextComponents} from "@drizzle/react-components";

const {ContractData, ContractForm} = newContextComponents;

export default ({drizzle, drizzleState}) => (
    <div>
        <div class="row">
            <div className="col-md-3">
                <strong>Income Tax Percentage</strong>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="MiltonConfiguration"
                    method="getIncomeTaxPercentage"
                    render={(value) => (
                        <div>
                            {value / 1000000000000000000}<br/>
                            <small>{value}</small>
                        </div>
                    )}
                />
                <hr/>
                <ContractForm
                    drizzle={drizzle}
                    contract="MiltonConfiguration"
                    method="setIncomeTaxPercentage"/>
            </div>
            <div className="col-md-3">
                <strong>Liquidation Deposit Fee Amount</strong>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="MiltonConfiguration"
                    method="getLiquidationDepositFeeAmount"
                    render={(value) => (
                        <div>
                            {value / 1000000000000000000}<br/>
                            <small>{value}</small>
                        </div>
                    )}
                />
                <hr/>
                <ContractForm
                    drizzle={drizzle}
                    contract="MiltonConfiguration"
                    method="setLiquidationDepositFeeAmount"/>
            </div>
            <div className="col-md-3">
                <strong>Open Fee Percentage</strong>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="MiltonConfiguration"
                    method="getOpeningFeePercentage"
                    render={(value) => (
                        <div>
                            {value / 1000000000000000000}<br/>
                            <small>{value}</small>
                        </div>
                    )}
                />
                <hr/>
                <ContractForm
                    drizzle={drizzle}
                    contract="MiltonConfiguration"
                    method="setOpeningFeePercentage"/>
            </div>
            <div className="col-md-3">
                <strong>IPOR Publication Fee Amount</strong>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="MiltonConfiguration"
                    method="getIporPublicationFeeAmount"
                    render={(value) => (
                        <div>
                            {value / 1000000000000000000}<br/>
                            <small>{value}</small>
                        </div>
                    )}
                />
                <hr/>
                <ContractForm
                    drizzle={drizzle}
                    contract="MiltonConfiguration"
                    method="setIporPublicationFeeAmount"/>
            </div>
        </div>
        <hr/>
        <div className="row">
            <div className="col-md-3">
                <strong>Max Income Tax Percentage</strong>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="MiltonConfiguration"
                    method="getMaxIncomeTaxPercentage"
                    render={(value) => (
                        <div>
                            {value / 1000000000000000000}<br/>
                            <small>{value}</small>
                        </div>
                    )}
                />
                <hr/>
                <ContractForm
                    drizzle={drizzle}
                    contract="MiltonConfiguration"
                    method="setMaxIncomeTaxPercentage"/>
            </div>
            <div className="col-md-3">
                <strong>Max Liquidation Deposit Fee Amount</strong>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="MiltonConfiguration"
                    method="getMaxLiquidationDepositFeeAmount"
                    render={(value) => (
                        <div>
                            {value / 1000000000000000000}<br/>
                            <small>{value}</small>
                        </div>
                    )}
                />
                <hr/>
                <ContractForm
                    drizzle={drizzle}
                    contract="MiltonConfiguration"
                    method="setMaxLiquidationDepositFeeAmount"/>
            </div>
            <div className="col-md-3">
                <strong>Max Open Fee Percentage</strong>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="MiltonConfiguration"
                    method="getMaxOpeningFeePercentage"
                    render={(value) => (
                        <div>
                            {value / 1000000000000000000}<br/>
                            <small>{value}</small>
                        </div>
                    )}
                />
                <hr/>
                <ContractForm
                    drizzle={drizzle}
                    contract="MiltonConfiguration"
                    method="setMaxOpeningFeePercentage"/>
            </div>
            <div className="col-md-3">
                <strong>Max IPOR Publication Fee Amount</strong>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="MiltonConfiguration"
                    method="getMaxIporPublicationFeeAmount"
                    render={(value) => (
                        <div>
                            {value / 1000000000000000000}<br/>
                            <small>{value}</small>
                        </div>
                    )}
                />
                <hr/>
                <ContractForm
                    drizzle={drizzle}
                    contract="MiltonConfiguration"
                    method="setMaxIporPublicationFeeAmount"/>
            </div>
        </div>
        <hr/>
        <div className="row">
            <div className="col-md-6">
                <strong>Liquidity Pool Max Utilization Percentage</strong>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="MiltonConfiguration"
                    method="getLiquidityPoolMaxUtilizationPercentage"
                    render={(value) => (
                        <div>
                            {value / 1000000000000000000}<br/>
                            <small>{value}</small>
                        </div>
                    )}
                />
                <hr/>
                <ContractForm
                    drizzle={drizzle}
                    contract="MiltonConfiguration"
                    method="setLiquidityPoolMaxUtilizationPercentage"/>
            </div>
            <div className="col-md-6"></div>

        </div>
        <hr/>
        <div className="row">
            <table className="table" align="center">
                <tr>
                    <th scope="col">Name of treasuers</th>
                    <th scope="col">USDT</th>
                    <th scope="col">USDC</th>
                    <th scope="col">DAI</th>
                </tr>
                <tr>
                    <td>
                        <strong>Charlie Treasuers</strong>
                        <br/>
                        <small>Manage IPOR publication fee balance</small>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonConfiguration"
                            method="getCharlieTreasurer"
                            methodArgs={["USDT"]}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonConfiguration"
                            method="getCharlieTreasurer"
                            methodArgs={["USDC"]}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonConfiguration"
                            method="getCharlieTreasurer"
                            methodArgs={["DAI"]}
                        />
                    </td>
                </tr>
                <tr>
                    <td>
                        <strong>Treasure Treasuers</strong>
                        <br/>
                        <small>Manage opening fee balance</small>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonConfiguration"
                            method="getTreasureTreasurer"
                            methodArgs={["USDT"]}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonConfiguration"
                            method="getTreasureTreasurer"
                            methodArgs={["USDC"]}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="MiltonConfiguration"
                            method="getTreasureTreasurer"
                            methodArgs={["DAI"]}
                        />
                    </td>
                </tr>
            </table>
        </div>
        <div className="row">
            <div className="col-md-6">
                <strong>Charlie Treasuers</strong>
                <ContractForm
                    drizzle={drizzle}
                    contract="MiltonConfiguration"
                    method="setCharlieTreasurer"/>
            </div>
            <div className="col-md-6">
                <strong>Treasure Treasuers</strong>
                <ContractForm
                    drizzle={drizzle}
                    contract="MiltonConfiguration"
                    method="setTreasureTreasurer"/>
            </div>
        </div>
    </div>
);