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
                        {drizzle.contracts.UsdtMockedToken.address}
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        USDC
                        <br />
                        {drizzle.contracts.UsdcMockedToken.address}
                        <br />
                        <br />
                    </th>
                    <th scope="col">
                        DAI
                        <br />
                        {drizzle.contracts.DaiMockedToken.address}
                        <br />
                        <br />
                    </th>
                </tr>
                <tr>
                    <td>
                        <br />
                        <strong>Ipor Configuration Address</strong>
                        <br />
                        <br />
                    </td>
                    <td>
                        <br />
                        {drizzle.contracts.IporAssetConfigurationUsdt.address}
                        <br />
                        <br />
                    </td>
                    <td>
                        <br />
                        {drizzle.contracts.IporAssetConfigurationUsdc.address}
                        <br />
                        <br />
                    </td>
                    <td>
                        <br />
                        {drizzle.contracts.IporAssetConfigurationDai.address}
                        <br />
                        <br />
                    </td>
                </tr>
                <tr>
                    <td>
                        <strong>Income Tax Percentage</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getIncomeTaxPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setIncomeTaxPercentage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getIncomeTaxPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setIncomeTaxPercentage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getIncomeTaxPercentage"
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
                            contract="IporAssetConfigurationDai"
                            method="setIncomeTaxPercentage"
                        />
                    </td>
                </tr>
                <tr>
                    <td>
                        <strong>Liquidation Deposit Fee Amount</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getLiquidationDepositAmount"
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />

                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setLiquidationDepositAmount"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getLiquidationDepositAmount"
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setLiquidationDepositAmount"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getLiquidationDepositAmount"
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
                            contract="IporAssetConfigurationDai"
                            method="setLiquidationDepositAmount"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Open Fee Percentage</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getOpeningFeePercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setOpeningFeePercentage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getOpeningFeePercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setOpeningFeePercentage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getOpeningFeePercentage"
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
                            contract="IporAssetConfigurationDai"
                            method="setOpeningFeePercentage"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>IPOR Publication Fee Amount</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getIporPublicationFeeAmount"
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setIporPublicationFeeAmount"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getIporPublicationFeeAmount"
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setIporPublicationFeeAmount"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getIporPublicationFeeAmount"
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
                            contract="IporAssetConfigurationDai"
                            method="setIporPublicationFeeAmount"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Minimum Collateralization Factor Value</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getMinCollateralizationFactorValue"
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setMinCollateralizationFactorValue"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getMinCollateralizationFactorValue"
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />

                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setMinCollateralizationFactorValue"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getMinCollateralizationFactorValue"
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
                            contract="IporAssetConfigurationDai"
                            method="setMinCollateralizationFactorValue"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Maximum Collateralization Factor Value</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getMaxCollateralizationFactorValue"
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setMaxCollateralizationFactorValue"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getMaxCollateralizationFactorValue"
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setMaxCollateralizationFactorValue"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getMaxCollateralizationFactorValue"
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
                            contract="IporAssetConfigurationDai"
                            method="setMaxCollateralizationFactorValue"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Opening Fee for Treasury Percentage</strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getOpeningFeeForTreasuryPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setOpeningFeeForTreasuryPercentage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getOpeningFeeForTreasuryPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setOpeningFeeForTreasuryPercentage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getOpeningFeeForTreasuryPercentage"
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
                            contract="IporAssetConfigurationDai"
                            method="setOpeningFeeForTreasuryPercentage"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>
                            Liquidity Pool Max Utilization Percentage
                        </strong>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getLiquidityPoolMaxUtilizationPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setLiquidityPoolMaxUtilizationPercentage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getLiquidityPoolMaxUtilizationPercentage"
                            render={(value) => (
                                <div>
                                    {value / 1000000}
                                    <br />
                                    <small>{value}</small>
                                </div>
                            )}
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setLiquidityPoolMaxUtilizationPercentage"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getLiquidityPoolMaxUtilizationPercentage"
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
                            contract="IporAssetConfigurationDai"
                            method="setLiquidityPoolMaxUtilizationPercentage"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Charlie Treasuers</strong>
                        <br />
                        <small>Manage IPOR publication fee token balance</small>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getCharlieTreasurer"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setCharlieTreasurer"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getCharlieTreasurer"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setCharlieTreasurer"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getCharlieTreasurer"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setCharlieTreasurer"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Treasure Manager</strong>
                        <br />
                        <small>Manage opening fee balance</small>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getTreasureTreasurer"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setTreasureTreasurer"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getTreasureTreasurer"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setTreasureTreasurer"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getTreasureTreasurer"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setTreasureTreasurer"
                        />
                    </td>
                </tr>

                <tr>
                    <td>
                        <strong>Asset Management Vault</strong>
                        <br />
                        <small>
                            Manage LP balance in external portals like AAVE &
                            Compound
                        </small>
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdt"
                            method="getAssetManagementVault"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdt"
                            method="setAssetManagementVault"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationUsdc"
                            method="getAssetManagementVault"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationUsdc"
                            method="setAssetManagementVault"
                        />
                    </td>
                    <td>
                        <ContractData
                            drizzle={drizzle}
                            drizzleState={drizzleState}
                            contract="IporAssetConfigurationDai"
                            method="getAssetManagementVault"
                        />
                        <ContractForm
                            drizzle={drizzle}
                            contract="IporAssetConfigurationDai"
                            method="setAssetManagementVault"
                        />
                    </td>
                </tr>
                <tr>
                    <table>
                        <thead>
                            <th>Asset</th> <th>Set Role</th>
                        </thead>
                        <tbody>
                            <tr>
                                <td>USDT</td>
                                <td>
                                    <ContractForm
                                        drizzle={drizzle}
                                        contract="IporAssetConfigurationUsdt"
                                        method="grantRole"
                                    />
                                </td>
                            </tr>
                            <tr>
                                <td>USDC</td>
                                <td>
                                    <ContractForm
                                        drizzle={drizzle}
                                        contract="IporAssetConfigurationUsdc"
                                        method="grantRole"
                                    />
                                </td>
                            </tr>
                            <tr>
                                <td>DAI</td>
                                <td>
                                    <ContractForm
                                        drizzle={drizzle}
                                        contract="IporAssetConfigurationDai"
                                        method="grantRole"
                                    />
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </tr>
                <tr>
                    <table>
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Value</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td>ADMIN_ROLE</td>
                                <td>
                                    0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775
                                </td>
                            </tr>
                            <tr>
                                <td>INCOME_TAX_PERCENTAGE_ROLE</td>
                                <td>
                                    0x1d60df71b356d37d065129ba494c44450d203a323cc11390563281105e480394
                                </td>
                            </tr>
                            <tr>
                                <td>INCOME_TAX_PERCENTAGE_ADMIN_ROLE</td>
                                <td>
                                    0xcaa6983304bafc9d674310f90270b5949e0bb6e51e706428584d7da457ddeccd
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    OPENING_FEE_FOR_TREASURY_PERCENTAGE_ROLE
                                </td>
                                <td>
                                    0x6d0de9008651a921e7ec84f14cdce94213af6041f456fcfc8c7e6fa897beab0f
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    OPENING_FEE_FOR_TREASURY_PERCENTAGE_ADMIN_ROLE
                                </td>
                                <td>
                                    0xebe66983650b4d8b57cb18fe7c97cdfe49625e06d8c6e70e646beb3a8ae73dd6
                                </td>
                            </tr>
                            <tr>
                                <td>LIQUIDATION_DEPOSIT_AMOUNT_ROLE</td>
                                <td>
                                    0xe5d97cc7ebc77e4491947e53b4b684cfaea4b3d5ec8734ba48d1fc4d2d54a42e
                                </td>
                            </tr>
                            <tr>
                                <td>LIQUIDATION_DEPOSIT_AMOUNT_ADMIN_ROLE</td>
                                <td>
                                    0xe7cc2a3bd9f3d49de9396c60dc8e9969986ea020b9bf72f8ab3527c64c7cbcf3
                                </td>
                            </tr>
                            <tr>
                                <td>OPENING_FEE_PERCENTAGE_ROLE</td>
                                <td>
                                    0xe5f1f8ca5512a616c0bd4bc9709dc97b4fc337caf7a3c160e93904247bd8daab
                                </td>
                            </tr>
                            <tr>
                                <td>OPENING_FEE_PERCENTAGE_ADMIN_ROLE</td>
                                <td>
                                    0x8714c5b454a0d07dd83274b33d478ceb04fb8767fe2079073b335f6e3a9feb14
                                </td>
                            </tr>
                            <tr>
                                <td>IPOR_PUBLICATION_FEE_AMOUNT_ROLE</td>
                                <td>
                                    0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1
                                </td>
                            </tr>
                            <tr>
                                <td>IPOR_PUBLICATION_FEE_AMOUNT_ADMIN_ROLE</td>
                                <td>
                                    0x789f25814c078f5d3a73f07837d3717096a7f31ff58dc1f3971a1aed3a8054d0
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ROLE
                                </td>
                                <td>
                                    0x53e7faacb3381a7b6b7185a9fc96bd9430da87ec709e6d3e0f009ed7c71e45ef
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    LIQUIDITY_POOLMAX_UTILIZATION_PERCENTAGE_ADMIN_ROLE
                                </td>
                                <td>
                                    0x9390cd14c303a3aaaa87f1f63728f95f237300898d55577f06a9b2f83904e4bd
                                </td>
                            </tr>
                            <tr>
                                <td>MAX_POSITION_TOTAL_AMOUNT_ROLE</td>
                                <td>
                                    0xbd6e7260790b38b2aece87cbeb2f1d97be9c3b1eb157efb80e7b3c341450caf2
                                </td>
                            </tr>
                            <tr>
                                <td>MAX_POSITION_TOTAL_AMOUNT_ADMIN_ROLE</td>
                                <td>
                                    0x7c8d8e1bbd6d112e40e3f26d08aabeb9e7e37771bd3877eb3850332e23f7c782
                                </td>
                            </tr>
                            <tr>
                                <td>SPREAD_PAY_FIXED_VALUE_ROLE</td>
                                <td>
                                    0x83d7135b2dfb3276d590bad8848fb596869644b2f5a647ccbdba6f13e445fb46
                                </td>
                            </tr>
                            <tr>
                                <td>SPREAD_PAY_FIXED_VALUE_ADMIN_ROLE</td>
                                <td>
                                    0x25c5c866e37916853ee1e8f7a6086f59f8a91e8d956b88c76e2da4a4757464a5
                                </td>
                            </tr>
                            <tr>
                                <td>COLLATERALIZATION_FACTOR_VALUE_ROLE</td>
                                <td>
                                    0xfa417488328f0d166e914b1aa9f0550c0823bf7e3a9e49d553e1ca6d505cc39e
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    COLLATERALIZATION_FACTOR_VALUE_ADMIN_ROLE
                                </td>
                                <td>
                                    0xc73b383cc34ef691c51adf836f82981b87c968081f10ae91077611045805b35e
                                </td>
                            </tr>
                            <tr>
                                <td>CHARLIE_TREASURER_ROLE</td>
                                <td>
                                    0x21b203ce7b3398e0ad35c938bc2c62a805ef17dc57de85e9d29052eac6d9d6f7
                                </td>
                            </tr>
                            <tr>
                                <td>CHARLIE_TREASURER_ADMIN_ROLE</td>
                                <td>
                                    0x0a8c46bed2194419383260fcc83e7085079a16a3dce173fb3d66eb1f81c71f6e
                                </td>
                            </tr>
                            <tr>
                                <td>TREASURE_TREASURER_ROLE</td>
                                <td>
                                    0x9cdee4e06275597b667c73a5eb52ed89fe6acbbd36bd9fa38146b1316abfbbc4
                                </td>
                            </tr>
                            <tr>
                                <td>TREASURE_TREASURER_ADMIN_ROLE</td>
                                <td>
                                    0x1ba824e22ad2e0dc1d7a152742f3b5890d88c5a849ed8e57f4c9d84203d3ea9c
                                </td>
                            </tr>
                            <tr>
                                <td>ASSET_MANAGEMENT_VAULT_ROLE</td>
                                <td>
                                    0x2a7b2b7d358f8b11f783d1505af660b492b725a034776176adc7c268915d5bd8
                                </td>
                            </tr>
                            <tr>
                                <td>ASSET_MANAGEMENT_VAULT_ADMIN_ROLE</td>
                                <td>
                                    0x1d3c5c61c32255cb922b09e735c0e9d76d2aacc424c3f7d9b9b85c478946fa26
                                </td>
                            </tr>
                            <tr>
                                <td>DECAY_FACTOR_VALUE_ROLE</td>
                                <td>
                                    0x94c58a89ab11d8b2894ecfbd6cb5c324f772536d0ea878a10cee7effe8ce98d0
                                </td>
                            </tr>
                            <tr>
                                <td>DECAY_FACTOR_VALUE_ADMIN_ROLE</td>
                                <td>
                                    0xed044c57d37423bb4623f9110729ee31cae04cae931fe5ab3b24fc2e474fbb70
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </tr>
            </table>
        </div>
    </div>
);
