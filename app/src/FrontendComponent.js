import React from "react";
import { newContextComponents } from "@drizzle/react-components";
import FrontendPositions from "./FrontendPositions";
import FrontendConfigurations from "./FrontendConfigurations";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div align="left">
        <table className="table">
            <tr>
                <th scope="col">Total Outstanding Notional</th>
                <th scope="col">
                    USDT
                    <br />
                    <small>{drizzle.contracts.MockTestnetTokenUsdt.address}</small>
                </th>
                <th scope="col">
                    USDC
                    <br />
                    <small>{drizzle.contracts.MockTestnetTokenUsdc.address}</small>
                </th>
                <th scope="col">
                    DAI
                    <br />
                    <small>{drizzle.contracts.MockTestnetTokenDai.address}</small>
                </th>
            </tr>
            <tr>
                <td>Liquidity Pool Balance</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.MockTestnetTokenUsdt.address]}
                        render={(value) => (
                            <div>
                                {value.liquidityPool / 1000000000000000000}
                                <br />
                                <small>{value.liquidityPool}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.MockTestnetTokenUsdc.address]}
                        render={(value) => (
                            <div>
                                {value.liquidityPool / 1000000000000000000}
                                <br />
                                <small>{value.liquidityPool}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.MockTestnetTokenDai.address]}
                        render={(value) => (
                            <div>
                                {value.liquidityPool / 1000000000000000000}
                                <br />
                                <small>{value.liquidityPool}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>Pay Fixed Total Notional Balance</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.MockTestnetTokenUsdt.address]}
                        render={(value) => (
                            <div>
                                {value.totalNotionalPayFixed / 1000000000000000000}
                                <br />
                                <small>{value.totalNotionalPayFixed}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.MockTestnetTokenUsdc.address]}
                        render={(value) => (
                            <div>
                                {value.totalNotionalPayFixed / 1000000000000000000}
                                <br />
                                <small>{value.totalNotionalPayFixed}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.MockTestnetTokenDai.address]}
                        render={(value) => (
                            <div>
                                {value.totalNotionalPayFixed / 1000000000000000000}
                                <br />
                                <small>{value.totalNotionalPayFixed}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>Receive Fixed Total Notional Balance</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.MockTestnetTokenUsdt.address]}
                        render={(value) => (
                            <div>
                                {value.totalNotionalReceiveFixed / 1000000000000000000}
                                <br />
                                <small>{value.totalNotionalReceiveFixed}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.MockTestnetTokenUsdc.address]}
                        render={(value) => (
                            <div>
                                {value.totalNotionalReceiveFixed / 1000000000000000000}
                                <br />
                                <small>{value.totalNotionalReceiveFixed}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.MockTestnetTokenDai.address]}
                        render={(value) => (
                            <div>
                                {value.totalNotionalReceiveFixed / 1000000000000000000}
                                <br />
                                <small>{value.totalNotionalReceiveFixed}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>Pay Fixed Total Collateral Balance</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.MockTestnetTokenUsdt.address]}
                        render={(value) => (
                            <div>
                                {value.totalCollateralPayFixed / 1000000000000000000}
                                <br />
                                <small>{value.totalCollateralPayFixed}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.MockTestnetTokenUsdc.address]}
                        render={(value) => (
                            <div>
                                {value.totalCollateralPayFixed / 1000000000000000000}
                                <br />
                                <small>{value.totalCollateralPayFixed}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.MockTestnetTokenDai.address]}
                        render={(value) => (
                            <div>
                                {value.totalCollateralPayFixed / 1000000000000000000}
                                <br />
                                <small>{value.totalCollateralPayFixed}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>Receive Fixed Total Collateral Balance</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.MockTestnetTokenUsdt.address]}
                        render={(value) => (
                            <div>
                                {value.totalCollateralReceiveFixed / 1000000000000000000}
                                <br />
                                <small>{value.totalCollateralReceiveFixed}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.MockTestnetTokenUsdc.address]}
                        render={(value) => (
                            <div>
                                {value.totalCollateralReceiveFixed / 1000000000000000000}
                                <br />
                                <small>{value.totalCollateralReceiveFixed}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getBalance"
                        methodArgs={[drizzle.contracts.MockTestnetTokenDai.address]}
                        render={(value) => (
                            <div>
                                {value.totalCollateralReceiveFixed / 1000000000000000000}
                                <br />
                                <small>{value.totalCollateralReceiveFixed}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
            <tr>
                <td>ipToken Exchange Rate</td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getIpTokenExchangeRate"
                        methodArgs={[drizzle.contracts.MockTestnetTokenUsdt.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getIpTokenExchangeRate"
                        methodArgs={[drizzle.contracts.MockTestnetTokenUsdc.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
                <td>
                    <ContractData
                        drizzle={drizzle}
                        drizzleState={drizzleState}
                        contract="MiltonFacadeDataProvider"
                        method="getIpTokenExchangeRate"
                        methodArgs={[drizzle.contracts.MockTestnetTokenDai.address]}
                        render={(value) => (
                            <div>
                                {value / 1000000000000000000}
                                <br />
                                <small>{value}</small>
                            </div>
                        )}
                    />
                </td>
            </tr>
        </table>
        <hr />
        <h5>Milton Facade Data Provider</h5>
        <div className="row">
            <div className="col-md-6">
                <label>Transfer Ownership</label>

                <ContractForm
                    drizzle={drizzle}
                    contract="MiltonFacadeDataProvider"
                    method="transferOwnership"
                />
            </div>
            <div className="col-md-6">
                <label>Confirm Transfer Ownership</label>

                <ContractForm
                    drizzle={drizzle}
                    contract="MiltonFacadeDataProvider"
                    method="confirmTransferOwnership"
                />
            </div>
        </div>

        <hr />
        <h5>Ipor Oracle Facade Data Provider</h5>
        <div className="row">
            <div className="col-md-6">
                <label>Transfer Ownership</label>

                <ContractForm
                    drizzle={drizzle}
                    contract="IporOracleFacadeDataProvider"
                    method="transferOwnership"
                />
            </div>
            <div className="col-md-6">
                <label>Confirm Transfer Ownership</label>

                <ContractForm
                    drizzle={drizzle}
                    contract="IporOracleFacadeDataProvider"
                    method="confirmTransferOwnership"
                />
            </div>
        </div>

        <hr />
        <h5>Frontend Configuration</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="MiltonFacadeDataProvider"
            method="getConfiguration"
            render={FrontendConfigurations}
        />
        <hr />
        <h5>My Positions - USDT</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="MiltonFacadeDataProvider"
            method="getMySwaps"
            methodArgs={[drizzle.contracts.MockTestnetTokenUsdt.address, 0, 50]}
            render={FrontendPositions}
        />
        <h5>My Positions - USDC</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="MiltonFacadeDataProvider"
            method="getMySwaps"
            methodArgs={[drizzle.contracts.MockTestnetTokenUsdc.address, 0, 50]}
            render={FrontendPositions}
        />
        <h5>My Positions - DAI</h5>
        <ContractData
            drizzle={drizzle}
            drizzleState={drizzleState}
            contract="MiltonFacadeDataProvider"
            method="getMySwaps"
            methodArgs={[drizzle.contracts.MockTestnetTokenDai.address, 0, 50]}
            render={FrontendPositions}
        />
    </div>
);
