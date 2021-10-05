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
                    method="getLiquidationDepositAmount"
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
                    method="setLiquidationDepositAmount"/>
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
                <strong>Minimum Collateralization Factor Value</strong>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="MiltonConfiguration"
                    method="getMinCollateralizationFactorValue"
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
                    method="setMinCollateralizationFactorValue"/>
            </div>
            <div className="col-md-3">
                <strong>Maximum Collateralization Factor Value</strong>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="MiltonConfiguration"
                    method="getMaxCollateralizationFactorValue"
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
                    method="setMaxCollateralizationFactorValue"/>
            </div>
            <div className="col-md-3">
                <strong>Opening Fee for Treasury Percentage</strong>
                <ContractData
                    drizzle={drizzle}
                    drizzleState={drizzleState}
                    contract="MiltonConfiguration"
                    method="getOpeningFeeForTreasuryPercentage"
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
                    method="setOpeningFeeForTreasuryPercentage"/>
            </div>
            <div className="col-md-3">
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
                            contract="IporAddressesManager"
                            method="getCharlieTreasurer"
                            methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAddressesManager"
                            method="getCharlieTreasurer"
                            methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAddressesManager"
                            method="getCharlieTreasurer"
                            methodArgs={[drizzle.contracts.DaiMockedToken.address]}
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
                            contract="IporAddressesManager"
                            method="getTreasureTreasurer"
                            methodArgs={[drizzle.contracts.UsdtMockedToken.address]}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAddressesManager"
                            method="getTreasureTreasurer"
                            methodArgs={[drizzle.contracts.UsdcMockedToken.address]}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAddressesManager"
                            method="getTreasureTreasurer"
                            methodArgs={[drizzle.contracts.DaiMockedToken.address]}
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
                    contract="IporAddressesManager"
                    method="setCharlieTreasurer"/>
            </div>
            <div className="col-md-6">
                <strong>Treasure Treasuers</strong>
                <ContractForm
                    drizzle={drizzle}
                    contract="IporAddressesManager"
                    method="setTreasureTreasurer"/>
            </div>
        </div>
    </div>
);