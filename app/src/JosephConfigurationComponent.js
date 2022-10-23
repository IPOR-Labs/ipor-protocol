import React from "react";
import {newContextComponents} from "@drizzle/react-components";

const {ContractData, ContractForm} = newContextComponents;

const small = {
    fontSize: '0.8rem'
}

export default ({drizzle, drizzleState}) => (
    <div>
        <div className="row">
            <table className="table" align="center">
                <tr>
                    <th scope="col">Parameter</th>
                    <th scope="col">
                        USDT
                        <br/>
                        <small>{drizzle.contracts.DrizzleUsdt.address}</small>
                        <br/>
                        <br/>
                    </th>
                    <th scope="col">
                        USDC
                        <br/>
                        <small>{drizzle.contracts.DrizzleUsdc.address}</small>
                        <br/>
                        <br/>
                    </th>
                    <th scope="col">
                        DAI
                        <br/>
                        <small>{drizzle.contracts.DrizzleDai.address}</small>
                        <br/>
                        <br/>
                    </th>
                    <th scope="col">
                        WETH
                        <br/>
                        <small>{drizzle.contracts.DrizzleWeth.address}</small>
                        <br/>
                        <br/>
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
                                    <br/>
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
                                    <br/>
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
                                    <br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephWeth"
                            method="getRedeemLpMaxUtilizationRate"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Milton Stanley Balance Rate</strong>
                        <br/>
                        <small>Value describe what percentage stay on Milton when rebalance cash between
                            Milton and Stanley</small>
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
                                    <br/>
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
                                    <br/>
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
                                    <br/>
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
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="DrizzleJosephWeth"
                            method="getMiltonStanleyBalanceRatio"
                            render={(value) => (
                                <div>
                                    {value / 1000000000000000000}
                                    <br/>
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="DrizzleJosephWeth"
                            method="setMiltonStanleyBalanceRatio"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Charlie Treasurer</strong>
                        <br/>
                        <small>Publication fee</small>
                    </td>
                    <td style={small}>
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
                    <td style={small}>
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
                    <td style={small}>
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
                    <td style={small}>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephWeth"
                                method="getCharlieTreasury"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephWeth"
                                method="setCharlieTreasury"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Treasury Treasurer</strong>
                        <br/>
                        <small>Income fee, part of opening fee</small>
                    </td>
                    <td style={small}>
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
                    <td style={small}>
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
                    <td style={small}>
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
                    <td style={small}>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephWeth"
                                method="getTreasury"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephWeth"
                                method="setTreasury"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Charlie Treasury Manager</strong>
                    </td>
                    <td style={small}>
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
                    <td style={small}>
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
                    <td style={small}>
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
                    <td style={small}>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephWeth"
                                method="getCharlieTreasuryManager"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephWeth"
                                method="setCharlieTreasuryManager"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Treasury Manager</strong>
                    </td>
                    <td style={small}>
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
                    <td style={small}>
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
                    <td style={small}>
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
                    <td style={small}>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephWeth"
                                method="getTreasuryManager"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephWeth"
                                method="setTreasuryManager"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Max Liquidity Pool Balance</strong>
                        <br/>
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
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephWeth"
                                method="getMaxLiquidityPoolBalance"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephWeth"
                                method="setMaxLiquidityPoolBalance"
                            />
                        </div>
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Max Liquidity Pool Account Contribution</strong>
                        <br/>
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
                    <td>
                        <div>
                            <ContractData
                                drizzle={drizzle}
                                drizzleState={drizzleState}
                                contract="DrizzleJosephWeth"
                                method="getMaxLpAccountContribution"
                            />
                            <ContractForm
                                drizzle={drizzle}
                                contract="DrizzleJosephWeth"
                                method="setMaxLpAccountContribution"
                            />
                        </div>
                    </td>
                </tr>
            </table>
        </div>
    </div>
);
