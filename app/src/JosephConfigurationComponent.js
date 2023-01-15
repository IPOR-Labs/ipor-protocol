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
                        <strong>Version</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephUsdt"
                            method="getVersion"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephUsdc"
                            method="getVersion"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephDai"
                            method="getVersion"
                        />
                    </td>
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
                        <strong>Asset Address</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephUsdt"
                            method="getAsset"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephUsdc"
                            method="getAsset"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephDai"
                            method="getAsset"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>IpToken Address</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephUsdt"
                            method="getIpToken"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephUsdc"
                            method="getIpToken"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephDai"
                            method="getIpToken"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Milton Address</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephUsdt"
                            method="getMilton"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephUsdc"
                            method="getMilton"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephDai"
                            method="getMilton"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Milton Storage Address</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephUsdt"
                            method="getMiltonStorage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephUsdc"
                            method="getMiltonStorage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephDai"
                            method="getMiltonStorage"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Stanley Address</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephUsdt"
                            method="getStanley"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephUsdc"
                            method="getStanley"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephDai"
                            method="getStanley"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Redeem Fee Rate</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephUsdt"
                            method="getRedeemFeeRate"
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
                            method="getRedeemFeeRate"
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
                            method="getRedeemFeeRate"
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
                        <br />
                        <small>
                            Value describe what percentage stay on Milton when rebalance cash
                            between Milton and Stanley
                        </small>
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
                        <br />
                        <small>Publication fee</small>
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
                        <strong>Charlie Treasury Manager</strong>
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
                        <strong>Treasury Manager</strong>
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

                <tr>
                    <td>
                        <strong>Max Liquidity Pool Balance</strong>
                        <br />
                        <small>Notice! Don't use decimals.</small>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephUsdt"
                                method="getMaxLiquidityPoolBalance"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdt"
                                method="setMaxLiquidityPoolBalance"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephUsdc"
                                method="getMaxLiquidityPoolBalance"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdc"
                                method="setMaxLiquidityPoolBalance"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephDai"
                                method="getMaxLiquidityPoolBalance"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephDai"
                                method="setMaxLiquidityPoolBalance"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Max Liquidity Pool Account Contribution</strong>
                        <br />
                        <small>Notice! Don't use decimals.</small>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephUsdt"
                                method="getMaxLpAccountContribution"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdt"
                                method="setMaxLpAccountContribution"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephUsdc"
                                method="getMaxLpAccountContribution"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdc"
                                method="setMaxLpAccountContribution"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephDai"
                                method="getMaxLpAccountContribution"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephDai"
                                method="setMaxLpAccountContribution"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Auto Rebalance Threshold</strong>
                        <br />
                        <small>
                            <strong>Notice when setup new value!</strong> Don't use decimals. The
                            value represents multiples of 1000.
                        </small>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephUsdt"
                                method="getAutoRebalanceThreshold"
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
                                method="setAutoRebalanceThreshold"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephUsdc"
                                method="getAutoRebalanceThreshold"
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
                                method="setAutoRebalanceThreshold"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephDai"
                                method="getAutoRebalanceThreshold"
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
                                method="setAutoRebalanceThreshold"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Add Appointed to Rebalance</strong>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdt"
                                method="addAppointedToRebalance"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdc"
                                method="addAppointedToRebalance"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephDai"
                                method="addAppointedToRebalance"
                            />
                        </div>
                    </td>
                </tr>
                <tr>
                    <td>
                        <strong>Remove Appointed to Rebalance</strong>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdt"
                                method="removeAppointedToRebalance"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephUsdc"
                                method="removeAppointedToRebalance"
                            />
                        </div>
                    </td>
                    <td>
                        <div>
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephDai"
                                method="removeAppointedToRebalance"
                            />
                        </div>
                    </td>
                </tr>
            </table>
        </div>
    </div>
);
