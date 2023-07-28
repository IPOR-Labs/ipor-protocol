// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "./Stanley.sol";

contract StanleyDaiDSR is
Initializable,
PausableUpgradeable,
ReentrancyGuardUpgradeable,
UUPSUpgradeable,
IporOwnableUpgradeable,
IStanley,
IStanleyInternal
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev deprecated
    address internal _assetDeprecated;
    /// @dev deprecated
    IIvToken internal _ivTokenDeprecated;
    /// @dev deprecated
    address internal _miltonDeprecated;
    /// @dev deprecated
    address internal _strategyAaveDeprecated;
    /// @dev deprecated
    address internal _strategyCompoundDeprecated;

    address internal immutable _asset;
    address internal immutable _ivToken;
    address internal immutable _milton;
    address internal immutable _strategyAave;
    address internal immutable _strategyCompound;
    address internal immutable _strategyDsr;

    struct StrategyData {
        address strategy;
        uint256 balance;
        uint256 apr;
    }

    struct StrategiesData {
        StrategyData aave;
        StrategyData compound;
        StrategyData dsr;
    }

    modifier onlyMilton() {
        require(_msgSender() == _milton, IporErrors.CALLER_NOT_MILTON);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address asset,
        address ivToken,
        address strategyAave,
        address strategyCompound,
        address strategyDsr,
        address milton
    ) {
        _disableInitializers();
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(ivToken != address(0), IporErrors.WRONG_ADDRESS);
        require(
            _getDecimals() == IERC20MetadataUpgradeable(asset).decimals(),
            IporErrors.WRONG_DECIMALS
        );

        IIvToken iivToken = IIvToken(ivToken);
        require(asset == iivToken.getAsset(), IporErrors.ADDRESSES_MISMATCH);

        _asset = asset;
        _milton = milton;
        _ivToken = ivToken;
        _strategyAave = strategyAave;
        _strategyCompound = strategyCompound;
        _strategyDsr = strategyDsr;
    }

    function initialize() public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function getVersion() external pure override returns (uint256) {
        return 3;
    }

    function getAsset() external view override returns (address) {
        return _asset;
    }

    function getIvToken() external view returns (address) {
        return _ivToken;
    }

    function getMilton() external view override returns (address) {
        return _milton;
    }

    function getStrategyAave() external view override returns (address) {
        return _strategyAave;
    }

    function getStrategyCompound() external view override returns (address) {
        return _strategyCompound;
    }

    function getStrategyDsr() external view returns (address) {
        return _strategyDsr;
    }

    function totalBalance(address who) external view override returns (uint256) {
        return _totalBalance(who);
    }

    function calculateExchangeRate() external view override returns (uint256 exchangeRate) {
        (, exchangeRate,) = _calcExchangeRate();
    }

    /**
     * @dev to deposit asset in higher apy strategy.
     * @notice only Milton can deposit
     * @param amount underlying token amount represented in 18 decimals
     */
    function deposit(uint256 amount)
    external
    override
    whenNotPaused
    onlyMilton
    returns (uint256 vaultBalance, uint256 depositedAmount)
    {
        require(amount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);
        uint256 assetAmount = IporMath.convertWadToAssetDecimals(amount, _getDecimals());
        require(assetAmount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);

        (
            ,
            uint256 exchangeRate,
            StrategiesData memory strategiesData
        ) = _calcExchangeRate();


        StrategyData[] memory sortedStrategies = _getMaxApyStrategy(strategiesData);

        uint256 ivTokenAmount = IporMath.division(amount * Constants.D18, exchangeRate);

        IERC20Upgradeable(_asset).safeTransferFrom(_msgSender(), address(this), assetAmount);

        depositedAmount = IStrategy(sortedStrategies[2].strategy).deposit(amount);

        IIvToken(_ivToken).mint(_msgSender(), ivTokenAmount);

        emit Deposit(
            block.timestamp,
            _msgSender(),
            sortedStrategies[2].strategy,
            exchangeRate,
            depositedAmount,
            ivTokenAmount
        );

        vaultBalance = _calculateTotalBalance(strategiesData) + depositedAmount;
    }

    function _getMaxApyStrategy(StrategiesData memory strategiesData)
    internal
    view
    returns (
        StrategyData[] memory sortedStrategies
    )
    {
        StrategyData[] memory strategies = new StrategyData[](3);
        strategiesData.aave.apr = IStrategy(strategiesData.aave.strategy).getApr();
        strategies[0] = strategiesData.aave;
        strategiesData.compound.apr = IStrategy(strategiesData.compound.strategy).getApr();
        strategies[1] = strategiesData.compound;
        strategiesData.dsr.apr = IStrategy(strategiesData.dsr.strategy).getApr();
        strategies[2] = strategiesData.dsr;

        sortedStrategies = _sortApr(strategies);
    }

    function withdraw(uint256 amount)
    external
    override
    whenNotPaused
    onlyMilton
    returns (uint256 withdrawnAmount, uint256 vaultBalance)
    {
        require(amount > 0, IporErrors.VALUE_NOT_GREATER_THAN_ZERO);

        IIvToken ivToken = IIvToken(_ivToken);
        IERC20Upgradeable asset = IERC20Upgradeable(_asset);
        IStrategy strategyAave = IStrategy(_strategyAave);
        IStrategy strategyCompound = IStrategy(_strategyCompound);

        StrategiesData memory strategiesData;
        (
        ,
        ,
            strategiesData
        ) = _calcExchangeRate();

        uint256 senderIvTokens = ivToken.balanceOf(_msgSender());
        StrategyData[] memory sortedStrategies = _getMaxApyStrategy(strategiesData);

        uint256 amountToWithdraw = amount;

        for (uint256 i; i < 3; ++i) {
            if (sortedStrategies[i].balance >= amountToWithdraw) {
                IStrategy(sortedStrategies[i].strategy).withdraw(amountToWithdraw);
                amountToWithdraw = 0;
            } else {
                IStrategy(sortedStrategies[i].strategy).withdraw(sortedStrategies[i].balance);
                amountToWithdraw -= sortedStrategies[i].balance;
            }
            if (amountToWithdraw == 0) {
                break;
            }
        }

        uint256 exchangeRate;
        (
        ,
            exchangeRate,
            strategiesData
        ) = _calcExchangeRate();

        uint256 assetBalanceStanley = IERC20Upgradeable(_asset).balanceOf(address(this));
        withdrawnAmount = IporMath.convertToWad(assetBalanceStanley, _getDecimals());
        uint256 ivTokenWithdrawnAmount = IporMath.division(withdrawnAmount * Constants.D18, exchangeRate);

        if (ivTokenWithdrawnAmount > senderIvTokens) {
            ivToken.burn(_msgSender(), senderIvTokens);
        } else {
            ivToken.burn(_msgSender(), ivTokenWithdrawnAmount);
        }

        if (assetBalanceStanley > 0) {
            //Always transfer all assets from Stanley to Milton
            IERC20Upgradeable(_asset).safeTransfer(_msgSender(), assetBalanceStanley);
        }

        return (withdrawnAmount, _calculateTotalBalance(strategiesData) - withdrawnAmount);
    }

    function withdrawAll()
    external
    override
    whenNotPaused
    onlyMilton
    returns (uint256 withdrawnAmount, uint256 vaultBalance)
    {
        address msgSender = _msgSender();
        IIvToken ivToken = IIvToken(_ivToken);
        IERC20Upgradeable asset = IERC20Upgradeable(_asset);

        (
            ,
            ,
            StrategiesData memory strategiesData
        ) = _calcExchangeRate();

        if (strategiesData.aave.balance > 0) {
            IStrategy(_strategyAave).withdraw(strategiesData.aave.balance);
        }
        if (strategiesData.compound.balance > 0) {
            IStrategy(_strategyCompound).withdraw(strategiesData.compound.balance);
        }
        if (strategiesData.dsr.balance > 0) {
            IStrategy(_strategyDsr).withdraw(strategiesData.dsr.balance);
        }

        ivToken.burn(msgSender, ivToken.balanceOf(msgSender));

        uint256 assetBalanceStanley = asset.balanceOf(address(this));

        //Always transfer all assets from Stanley to Milton
        asset.safeTransfer(msgSender, assetBalanceStanley);

        withdrawnAmount = IporMath.convertToWad(assetBalanceStanley, _getDecimals());

        ivToken.burn(_msgSender(), ivToken.balanceOf(_msgSender()));


    }

    function withdrawAllFromStrategy(address strategy) external onlyMilton returns (uint256 withdrawnAmount, uint256 vaultBalance)  {
        require(strategy == _strategyAave || strategy == _strategyCompound || strategy == _strategyDsr, IporErrors.WRONG_ADDRESS);

        uint256 balance = IStrategy(strategy).balanceOf();

        IStrategy(strategy).withdraw(balance);

        uint256 assetBalanceStanley = IERC20Upgradeable(_asset).balanceOf(address(this));
        withdrawnAmount = IporMath.convertToWad(assetBalanceStanley, _getDecimals());

        (
            ,
            uint256 exchangeRate,
            StrategiesData memory strategiesData
        ) = _calcExchangeRate();

        uint256 senderIvTokens = IIvToken(_ivToken).balanceOf(_msgSender());
        uint256 ivTokenWithdrawnAmount = IporMath.division(withdrawnAmount * Constants.D18, exchangeRate);

        if (ivTokenWithdrawnAmount > senderIvTokens) {
            IIvToken(_ivToken).burn(_msgSender(), senderIvTokens);
        } else {
            IIvToken(_ivToken).burn(_msgSender(), ivTokenWithdrawnAmount);
        }

        if (assetBalanceStanley > 0) {
            //Always transfer all assets from Stanley to Milton
            IERC20Upgradeable(_asset).safeTransfer(_msgSender(), assetBalanceStanley);
        }

        return (withdrawnAmount, _calculateTotalBalance(strategiesData) - withdrawnAmount);
    }

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    function _getDecimals() internal pure virtual returns (uint256) {
        return 18;
    }

    function _totalBalance(address who) internal view returns (uint256) {
        (, uint256 exchangeRate,) = _calcExchangeRate();
        return IporMath.division(IIvToken(_ivToken).balanceOf(who) * exchangeRate, Constants.D18);
    }


    function _calcExchangeRate()
    internal
    view
    returns (
        uint256 ivTokenTotalSupply,
        uint256 exchangeRate,
        StrategiesData memory strategiesData
    )
    {
        strategiesData.aave.balance = IStrategy(_strategyAave).balanceOf();
        strategiesData.compound.balance = IStrategy(_strategyCompound).balanceOf();
        strategiesData.dsr.balance = IStrategy(_strategyDsr).balanceOf();

        uint256 totalAssetBalance = _calculateTotalBalance(strategiesData);

        ivTokenTotalSupply = IIvToken(_ivToken).totalSupply();

        if (totalAssetBalance == 0 || ivTokenTotalSupply == 0) {
            exchangeRate = Constants.D18;
        } else {
            exchangeRate = IporMath.division(totalAssetBalance * Constants.D18, ivTokenTotalSupply);
        }
    }

    function _calculateTotalBalance(StrategiesData memory strategiesData)
    internal
    view
    returns (uint256)
    {
        return
            strategiesData.aave.balance +
            strategiesData.compound.balance +
            strategiesData.dsr.balance + IERC20Upgradeable(_asset).balanceOf(address(this));
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _sortApr(StrategyData[] memory data) internal view returns (StrategyData[] memory) {
        _quickSortApr(data, int256(0), int256(data.length - 1));
        return data;
    }

    function _quickSortApr(
        StrategyData[] memory arr,
        int256 left,
        int256 right
    ) internal view {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        StrategyData memory pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)].apr < pivot.apr) i++;
            while (pivot.apr < arr[uint256(j)].apr) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                i++;
                j--;
            }
        }
        if (left < j) _quickSortApr(arr, left, j);
        if (i < right) _quickSortApr(arr, i, right);
    }


    function migrateAssetToStrategyWithMaxApr() external whenNotPaused onlyOwner {}

    function setStrategyAave(address newStrategyAddr) external override whenNotPaused onlyOwner {}

    function setStrategyCompound(address newStrategyAddr)
    external
    override
    whenNotPaused
    onlyOwner
    {}

    function setMilton(address newMilton) external override whenNotPaused onlyOwner {}
}
