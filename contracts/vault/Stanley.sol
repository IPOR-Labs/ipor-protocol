// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IPOR/IStrategy.sol";
import "../interfaces/IStanley.sol";
import "../interfaces/IIporOwnableUpgradeable.sol";
import "../security/IporOwnableUpgradeable.sol";
import "./interfaces/IIvToken.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./ExchangeRate.sol";
import "../IporErrors.sol";

// TODO: Add function transferStrategyOwnership
// TODO: Add IStanley with busineess methods
contract Stanley is
    UUPSUpgradeable,
    PausableUpgradeable,
    IporOwnableUpgradeable,
    ExchangeRate,
    IStanley
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint8 internal _decimals;
    address internal _asset;
    IIvToken private _ivToken;

    address private _milton;
    address private _aaveStrategy;
    address private _aaveShareToken;
    address private _compoundStrategy;
    address private _compoundShareToken;

    /**
     * @dev Deploy IPORVault.
     * @notice Deploy IPORVault.
     * @param asset underlying token like DAI, USDT etc.
     */
    function initialize(
        address asset,
        address ivToken,
        address strategyAave,
        address strategyCompound
    ) public initializer {
        __Ownable_init();
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(ivToken != address(0), IporErrors.WRONG_ADDRESS);

        _asset = asset;
        _decimals = ERC20Upgradeable(_asset).decimals();
        _ivToken = IIvToken(ivToken);

        _setAaveStrategy(strategyAave);
        _setCompoundStrategy(strategyCompound);
    }

    modifier onlyMilton() {
        require(msg.sender == _milton, IporErrors.CALLER_NOT_MILTON);
        _;
    }

    function totalBalance(address who)
        external
        view
        override
        returns (uint256)
    {
        return _totalBalance(who);
    }

    /**
     * @dev to deposit asset in higher apy strategy.
     * @notice only owner can deposit.
     * @param amount amount to deposit.
     */
    //  TODO: ADD tests for amount = 0
    function deposit(uint256 amount)
        external
        override
        onlyMilton
        returns (uint256)
    {
        require(amount != 0, IporErrors.UINT_SHOULD_BE_GRATER_THEN_ZERO);

        (IStrategy strategyMaxApy, , ) = _getMaxApyStrategy();

        uint256 decimals = _decimals;

        (
            uint256 exchangeRate,
            uint256 balanceAave,
            uint256 balanceCompound
        ) = _calcExchangeRate(decimals);

        uint256 ivTokenValue = IporMath.division(
            amount * decimals,
            exchangeRate
        );

        _depositToStrategy(strategyMaxApy, amount);

        _ivToken.mint(msg.sender, ivTokenValue);

        emit Deposit(
            block.timestamp,
            msg.sender,
            address(strategyMaxApy),
            exchangeRate,
            amount,
            ivTokenValue
        );

        return balanceAave + balanceCompound + amount;
    }

    /**
     * @dev to withdraw asset from current strategy.
     * @notice only owner can withdraw.
     * @param amount of shares want to withdraw.
            Shares means aTokens, cTokens
    */
    function withdraw(uint256 amount)
        external
        override
        onlyMilton
        returns (uint256 withdrawnValue, uint256 balance)
    {
        require(amount != 0, IporErrors.UINT_SHOULD_BE_GRATER_THEN_ZERO);

        uint256 decimals = _decimals;
        IIvToken ivToken = _ivToken;

        (
            IStrategy strategyMaxApy,
            IStrategy strategyAave,
            IStrategy strategyCompound
        ) = _getMaxApyStrategy();

        (
            uint256 exchangeRate,
            uint256 balanceAave,
            uint256 balanceCompound
        ) = _calcExchangeRate(decimals);

        uint256 ivTokenValue = IporMath.division(
            amount * decimals,
            exchangeRate
        );

        require(
            ivToken.balanceOf(msg.sender) >= ivTokenValue,
            IporErrors.UINT_SHOULD_BE_GRATER_THEN_ZERO
        );

        if (
            address(strategyMaxApy) == _compoundStrategy &&
            amount <= balanceAave
        ) {
            ivToken.burn(msg.sender, ivTokenValue);
            _withdrawFromStrategy(
                address(strategyAave),
                amount,
                ivTokenValue,
                exchangeRate,
                true
            );

            withdrawnValue = amount;
            balance = balanceAave + balanceCompound - withdrawnValue;

            return (withdrawnValue, balance);
        } else if (amount <= balanceCompound) {
            ivToken.burn(msg.sender, ivTokenValue);
            _withdrawFromStrategy(
                address(strategyCompound),
                amount,
                ivTokenValue,
                exchangeRate,
                true
            );

            withdrawnValue = amount;
            balance = balanceAave + balanceCompound - withdrawnValue;

            return (withdrawnValue, balance);
        }

        if (
            address(strategyMaxApy) == _aaveStrategy &&
            amount <= balanceCompound
        ) {
            ivToken.burn(msg.sender, ivTokenValue);
            _withdrawFromStrategy(
                address(strategyCompound),
                amount,
                ivTokenValue,
                exchangeRate,
                true
            );

            withdrawnValue = amount;
            balance = balanceAave + balanceCompound - withdrawnValue;

            return (withdrawnValue, balance);
        } else if (amount <= balanceAave) {
            ivToken.burn(msg.sender, ivTokenValue);
            _withdrawFromStrategy(
                address(strategyAave),
                amount,
                ivTokenValue,
                exchangeRate,
                true
            );

            withdrawnValue = amount;
            balance = balanceAave + balanceCompound - withdrawnValue;

            return (withdrawnValue, balance);
        }

        if (balanceAave < balanceCompound) {
            uint256 ivTokenValuePart = IporMath.division(
                balanceCompound * decimals,
                exchangeRate
            );

            _ivToken.burn(msg.sender, ivTokenValuePart);
            _withdrawFromStrategy(
                address(strategyCompound),
                balanceCompound,
                ivTokenValuePart,
                exchangeRate,
                true
            );

            withdrawnValue = balanceCompound;
        } else {
            // TODO: Add tests for DAI(18 decimals) and for USDT (6 decimals)
            uint256 ivTokenValuePart = IporMath.division(
                balanceAave * decimals,
                exchangeRate
            );
            ivToken.burn(msg.sender, ivTokenValuePart);
            _withdrawFromStrategy(
                address(strategyAave),
                balanceAave,
                ivTokenValuePart,
                exchangeRate,
                true
            );
            withdrawnValue = balanceAave;
        }

        balance = balanceAave + balanceCompound - withdrawnValue;
        return (withdrawnValue, balance);
    }

    function withdrawAll() external onlyMilton {
        uint256 decimals = _decimals;
        IStrategy strategyAave = IStrategy(_aaveStrategy);

        (uint256 exchangeRate, , ) = _calcExchangeRate(decimals);

        uint256 amountAave = strategyAave.balanceOf();
        uint256 ivTokenValueAave = IporMath.division(
            amountAave * decimals,
            exchangeRate
        );

        _withdrawFromStrategy(
            address(strategyAave),
            amountAave,
            ivTokenValueAave,
            exchangeRate,
            false
        );

        IStrategy strategyCompound = IStrategy(_compoundStrategy);

        uint256 amountCompound = strategyCompound.balanceOf();
        uint256 ivTokenValueCompound = IporMath.division(
            amountCompound * decimals,
            exchangeRate
        );

        _withdrawFromStrategy(
            address(strategyCompound),
            amountCompound,
            ivTokenValueCompound,
            exchangeRate,
            false
        );

        uint256 balance = ERC20Upgradeable(_asset).balanceOf(address(this));
        IERC20Upgradeable(_asset).safeTransfer(msg.sender, balance);
    }

    // Find highest apy strategy to deposit underlying asset
    function _getMaxApyStrategy()
        internal
        view
        returns (
            IStrategy strategyMaxApy,
            IStrategy strategyAave,
            IStrategy strategyCompound
        )
    {
        strategyAave = IStrategy(_aaveStrategy);
        strategyCompound = IStrategy(_compoundStrategy);

        if (strategyAave.getApy() < strategyCompound.getApy()) {
            strategyMaxApy = strategyCompound;
        } else {
            strategyMaxApy = strategyAave;
        }
    }

    function _totalBalance(address who) internal view returns (uint256) {
        (uint256 exchangeRate, , ) = _calcExchangeRate(_decimals);
        return _ivToken.balanceOf(who) * exchangeRate;
    }

    function setAaveStrategy(address strategyAddress) external onlyOwner {
        _setAaveStrategy(strategyAddress);
    }

    function setCompoundStrategy(address strategy) external onlyOwner {
        _setCompoundStrategy(strategy);
    }

    function setMilton(address milton) external onlyOwner {
        _milton = milton;
    }

    /**
     * @dev to migrate all asset from current strategy to another higher apy strategy.
     * @notice only owner can migrate.
     */
    function migrateAssetInMaxApyStrategy() external onlyOwner {
        (
            IStrategy strategyMaxApy,
            IStrategy strategyAave,
            IStrategy strategyCompound
        ) = _getMaxApyStrategy();

        address from;

        if (address(strategyMaxApy) == address(strategyAave)) {
            from = address(strategyCompound);
            uint256 _shares = IERC20Upgradeable(_compoundShareToken).balanceOf(
                from
            );
            require(_shares > 0, IporErrors.UINT_SHOULD_BE_GRATER_THEN_ZERO);
            strategyCompound.withdraw(_shares);
        } else {
            from = address(strategyAave);
            uint256 _shares = IERC20Upgradeable(_aaveShareToken).balanceOf(
                from
            );
            require(_shares > 0, IporErrors.UINT_SHOULD_BE_GRATER_THEN_ZERO);
            strategyAave.withdraw(_shares);
        }

        uint256 amount = ERC20Upgradeable(_asset).balanceOf(address(this));

        _depositToStrategy(strategyMaxApy, amount);

        emit MigrateAsset(from, address(strategyMaxApy), amount);
    }

    /**
     * @dev claim Gov token from current strategy.
     * @notice only owner can claim.
     * @param _account send claimed gove token to _account
     */
    // TODO: Consider to convert _account variable in contract and change fincton to no parameters
    function aaveDoClaim(address _account) external payable onlyOwner {
        _doClaim(_account, _aaveStrategy);
    }

    function aaveBeforeClaim(address[] memory assets, uint256 amount)
        external
        payable
        onlyOwner
    {
        IStrategy(_aaveStrategy).beforeClaim(assets, amount);
    }

    // TODO: Consider to convert _account variable in contract and change fincton to no parameters
    function compoundDoClaim(address _account) external payable onlyOwner {
        _doClaim(_account, _compoundStrategy);
    }

    // TODO: Consider reorder checks in this way that method will have less calculation (gas opt)
    function _setCompoundStrategy(address strategyAddress) internal {
        require(strategyAddress != address(0), IporErrors.WRONG_ADDRESS);
        IERC20Upgradeable asset = IERC20Upgradeable(_asset);

        IStrategy strategy = IStrategy(strategyAddress);
        IERC20Upgradeable csToken = IERC20Upgradeable(_compoundShareToken);
        if (_compoundStrategy != address(0)) {
            asset.safeDecreaseAllowance(_compoundStrategy, 0);
            csToken.safeDecreaseAllowance(_compoundStrategy, 0);
        }
        address _compoundUnderlyingToken = strategy.getAsset();
        require(
            _compoundUnderlyingToken == address(asset),
            IporErrors.UNDERLYINGTOKEN_IS_NOT_COMPATIBLE
        );

        _compoundStrategy = strategyAddress;
        _compoundShareToken = IStrategy(strategyAddress).shareToken();
        IERC20Upgradeable newCsToken = IERC20Upgradeable(_compoundShareToken);
        asset.safeApprove(strategyAddress, 0);
        asset.safeApprove(strategyAddress, type(uint256).max);
        newCsToken.safeApprove(strategyAddress, 0);
        newCsToken.safeApprove(strategyAddress, type(uint256).max);
        emit SetStrategy(strategyAddress, _compoundShareToken);
    }

    function _setAaveStrategy(address strategyAddress) internal {
        require(strategyAddress != address(0), IporErrors.WRONG_ADDRESS);

        IERC20Upgradeable asset = ERC20Upgradeable(_asset);
        IStrategy strategy = IStrategy(strategyAddress);

        if (_aaveStrategy != address(0)) {
            asset.safeDecreaseAllowance(_aaveStrategy, 0);
            IERC20Upgradeable(_aaveShareToken).safeDecreaseAllowance(
                _aaveStrategy,
                0
            );
        }
        address _aaveUnderlyingToken = strategy.getAsset();
        require(
            _aaveUnderlyingToken == address(asset),
            IporErrors.UNDERLYINGTOKEN_IS_NOT_COMPATIBLE
        );

        _aaveShareToken = strategy.shareToken();
        IERC20Upgradeable asToken = IERC20Upgradeable(_aaveShareToken);
        _aaveStrategy = strategyAddress;
        asset.safeApprove(strategyAddress, 0);
        asset.safeApprove(strategyAddress, type(uint256).max);
        asToken.safeApprove(strategyAddress, 0);
        asToken.safeApprove(strategyAddress, type(uint256).max);
        emit SetStrategy(strategyAddress, _aaveShareToken);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @dev to withdraw asset from current strategy.
     * @notice internal method.
     * @param strategyAddress strategy from amount to withdraw
     * @param amount is interest bearing token like aDAI, cDAI etc.
     */
    function _withdrawFromStrategy(
        address strategyAddress,
        uint256 amount,
        uint256 ivTokenValue,
        uint256 exchangeRate,
        bool transfer
    ) internal {
        if (amount != 0) {
            IStrategy(strategyAddress).withdraw(amount);

            IERC20Upgradeable asset = IERC20Upgradeable(_asset);

            uint256 balance = asset.balanceOf(address(this));

            if (transfer) {
                asset.safeTransfer(msg.sender, balance);
            }

            emit Withdraw(
                block.timestamp,
                strategyAddress,
                msg.sender,
                exchangeRate,
                amount,
                ivTokenValue
            );
        }
    }

    function _doClaim(address _account, address strategyAddress) internal {
        require(_account != address(0), IporErrors.WRONG_ADDRESS);
        IStrategy strategy = IStrategy(strategyAddress);
        address[] memory assets = new address[](1);
        assets[0] = strategy.shareToken();
        strategy.doClaim(_account, assets);
        emit DoClaim(strategyAddress, _account);
    }

    /**  Internal Methods */
    /**
     * @dev to deposit asset in current strategy.
     * @notice internal method.
     * @param strategyAddress strategy from amount to deposit
     * @param amount _amount is _asset token like DAI.
     */
    function _depositToStrategy(IStrategy strategyAddress, uint256 amount)
        internal
    {
        IERC20Upgradeable(_asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        strategyAddress.deposit(amount);
    }

    function _calcExchangeRate(uint256 decimals)
        internal
        view
        returns (
            uint256 exchangeRate,
            uint256 balanceAave,
            uint256 balanceCompound
        )
    {
        balanceAave = IStrategy(_aaveStrategy).balanceOf();
        balanceCompound = IStrategy(_compoundStrategy).balanceOf();

        uint256 totalAssetBalance = balanceAave + balanceCompound;

        uint256 ivTokenBalance = _ivToken.totalSupply();

        if (totalAssetBalance == 0 || ivTokenBalance == 0) {
            exchangeRate = 10**decimals;
        } else {
            exchangeRate = IporMath.division(
                totalAssetBalance * decimals,
                ivTokenBalance
            );
        }
    }
}
