import React from "react";
import { newContextComponents } from "@drizzle/react-components";

const { ContractData, ContractForm } = newContextComponents;

export default ({ drizzle, drizzleState }) => (
    <div>
        <div className="row">
            <table className="table" align="center">
                <tr>
                    <th scope="col">Parameter</th>
                    <th scope="col">
                        USDT
                        <br />
                        {drizzle.contracts.DrizzleUsdt.address}
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        USDC
                        <br />
                        {drizzle.contracts.DrizzleUsdc.address}
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        DAI
                        <br />
                        {drizzle.contracts.DrizzleDai.address}
                        <br />
                        <br />
                    </th>
                </tr>

                <tr>
                    <td>
                        <strong>Redeem Liquidity Pool Max Utilization Rate</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephUsdt"
                            method="getRedeemLpMaxUtilizationRate"
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
                            contract="DrizzleJosephUsdc"
                            method="getRedeemLpMaxUtilizationRate"
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
                            contract="DrizzleJosephDai"
                            method="getRedeemLpMaxUtilizationRate"
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

                <tr>
                    <td>
                        <strong>Milton Stanley Balance Rate</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephUsdt"
                            method="getMiltonStanleyBalanceRatio"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="DrizzleJosephUsdt"
                            method="setMiltonStanleyBalanceRatio"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephUsdc"
                            method="getMiltonStanleyBalanceRatio"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="DrizzleJosephUsdc"
                            method="setMiltonStanleyBalanceRatio"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephDai"
                            method="getMiltonStanleyBalanceRatio"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="DrizzleJosephDai"
                            method="setMiltonStanleyBalanceRatio"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Charlie Treasurer</strong>
                        <small></small>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephUsdt"
                                method="getCharlieTreasury"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdt"
                                method="setCharlieTreasury"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephUsdc"
                                method="getCharlieTreasury"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdc"
                                method="setCharlieTreasury"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephDai"
                                method="getCharlieTreasury"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephDai"
                                method="setCharlieTreasury"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Treasury Treasurer</strong>
                        <br />
                        <small>Income fee, part of opening fee</small>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephUsdt"
                                method="getTreasury"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdt"
                                method="setTreasury"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephUsdc"
                                method="getTreasury"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdc"
                                method="setTreasury"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephDai"
                                method="getTreasury"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephDai"
                                method="setTreasury"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Publication Fee Transferer</strong>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephUsdt"
                                method="getCharlieTreasuryManager"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdt"
                                method="setCharlieTreasuryManager"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephUsdc"
                                method="getCharlieTreasuryManager"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdc"
                                method="setCharlieTreasuryManager"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephDai"
                                method="getCharlieTreasuryManager"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephDai"
                                method="setCharlieTreasuryManager"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Treasury Transferer</strong>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephUsdt"
                                method="getTreasuryManager"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdt"
                                method="setTreasuryManager"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephUsdc"
                                method="getTreasuryManager"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdc"
                                method="setTreasuryManager"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephDai"
                                method="getTreasuryManager"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephDai"
                                method="setTreasuryManager"
                            />
                        </div>
                    </td>
                </tr>
            </table>
        </div>
    </div>
);
