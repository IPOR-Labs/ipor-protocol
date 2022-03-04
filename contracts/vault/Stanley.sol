// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IPOR/IStrategy.sol";
import "../interfaces/IIporOwnableUpgradeable.sol";
import "./interfaces/IIvToken.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./StanleyAccessControl.sol";
import "./ExchangeRate.sol";
import "../IporErrors.sol";

// TODO: Add function transferStrategyOwnership
// TODO: Add IStanley with busineess methods
contract Stanley is
    UUPSUpgradeable,
    PausableUpgradeable,
    StanleyAccessControl,
    ExchangeRate
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint8 internal _decimals;
    address internal _asset;
    IIvToken private _ivToken;

    address private _aaveStrategy;
    address private _aaveShareToken;
    address private _compoundStrategy;
    address private _compoundShareToken;

    // TODO: maybe better move to interface (all in AM)
    event SetStrategy(address strategy, address shareToken);
    event Deposit(address strategy, uint256 amount);
    event Withdraw(address strategy, uint256 shares);
    event MigrateAsset(
        address currentStrategy,
        address newStrategy,
        uint256 amount
    );
    event DoClaim(address strategyAddress, address _account);

    /**
     * @dev Deploy IPORVault.
     * @notice Deploy IPORVault.
     * @param asset underlying token like DAI, USDT etc.
     */
    function initialize(
        address asset,
        address ivToken,
        address aaveStrategy,
        address compoundStrategy
    ) public initializer {
        _init();
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(ivToken != address(0), IporErrors.WRONG_ADDRESS);

        _asset = asset;
        _decimals = ERC20Upgradeable(asset).decimals();
        _ivToken = IIvToken(ivToken);

        _setAaveStrategy(aaveStrategy);
        _setCompoundStrategy(compoundStrategy);
    }

    // Find highest apy strategy to deposit underlying asset
    function getMaxApyStrategy() public view returns (IStrategy depositAsset) {
        IStrategy aave = IStrategy(_aaveStrategy);
        IStrategy compound = IStrategy(_compoundStrategy);
        if (aave.getApy() < compound.getApy()) {
            return compound;
        }
        return aave;
    }

    // TODO: totalStrategiesBalance =>  totalBalance
    function totalStrategiesBalance() public view returns (uint256) {
        return
            IStrategy(_aaveStrategy).balanceOf() +
            IStrategy(_compoundStrategy).balanceOf();
    }

    /**
     * @dev to deposit asset in higher apy strategy.
     * @notice only owner can deposit.
     * @param amount amount to deposit.
     */
    //  TODO: ADD tests for amount = 0
    //  TODO: return balanse before deposit
    function deposit(uint256 amount) external onlyRole(_DEPOSIT_ROLE) {
        require(amount != 0, IporErrors.UINT_SHOULD_BE_GRATER_THEN_ZERO);

        IStrategy strategy = getMaxApyStrategy();

        uint256 totalAsset = totalStrategiesBalance();
        uint256 tokenAmount = ivToken.totalSupply();
        uint256 exchangeRate = _calculateExchangeRate(totalAsset, tokenAmount);
        _deposit(strategy, amount);

        _ivToken.mint(
            msg.sender,
            IporMath.division(amount * 1e18, exchangeRate)
        );

        emit Deposit(address(strategy), amount);
    }

    function setCompoundStrategy(address strategy)
        external
        onlyRole(_GOVERNANCE_ROLE)
    {
        _setCompoundStrategy(strategy);
    }

    function confirmTransferOwnership(address strategy)
        external
        onlyRole(_GOVERNANCE_ROLE)
    {
        IIporOwnableUpgradeable(strategy).confirmTransferOwnership();
    }

    function setAaveStrategy(address strategyAddress)
        external
        onlyRole(_GOVERNANCE_ROLE)
    {
        _setAaveStrategy(strategyAddress);
    }

    /**
     * @dev to withdraw asset from current strategy.
     * @notice only owner can withdraw.
     * @param _tokens amount of shares want to withdraw.
            Shares means aTokens, cTokens
    */
    // TODO: return amount of withdraw,
    // TODO: balanse before withdraw and aftre
    function withdraw(uint256 _tokens) external onlyRole(_WITHDRAW_ROLE) {
        require(_tokens != 0, IporErrors.UINT_SHOULD_BE_GRATER_THEN_ZERO);
        

        require(
            _ivToken.balanceOf(msg.sender) >= _tokens,
            IporErrors.UINT_SHOULD_BE_GRATER_THEN_ZERO
        );

        IStrategy maxApyStrategy = getMaxApyStrategy();

        uint256 _totalAsset = totalStrategiesBalance();
        uint256 _tokenAmount = _ivToken.totalSupply();
        uint256 _exchangeRateRoundDown = _calculateExchangeRateRoundDown(
            _totalAsset,
            _tokenAmount
        );
        uint256 _exchangeRate = _calculateExchangeRate(
            _totalAsset,
            _tokenAmount
        );
        uint256 amount = IporMath.division(
            _tokens * _exchangeRateRoundDown,
            1e18
        );

        IStrategy aaveStrategy = IStrategy(_aaveStrategy);
        uint256 aaveBalance = aaveStrategy.balanceOf();
        IStrategy compoundStrategy = IStrategy(_compoundStrategy);
        uint256 compoundBalance = compoundStrategy.balanceOf();

        if (
            address(maxApyStrategy) == _compoundStrategy &&
            amount <= aaveBalance
        ) {
            _ivToken.burn(msg.sender, _tokens);
            _withdraw(address(aaveStrategy), amount, true);
            return;
        } else if (amount <= compoundBalance) {
            _ivToken.burn(msg.sender, _tokens);
            _withdraw(address(compoundStrategy), amount, true);
            return;
        }
        if (
            address(maxApyStrategy) == _aaveStrategy &&
            amount <= compoundBalance
        ) {
            _ivToken.burn(msg.sender, _tokens);
            _withdraw(address(compoundStrategy), amount, true);
            return;
        } else if (amount <= aaveBalance) {
            _ivToken.burn(msg.sender, _tokens);
            _withdraw(address(aaveStrategy), amount, true);
            return;
        }
        if (aaveBalance < compoundBalance) {
            uint256 tokensToBurn = IporMath.division(
                compoundBalance * 1e18,
                _exchangeRate
            );
            token.burn(msg.sender, tokensToBurn);
            _withdraw(address(compoundStrategy), compoundBalance, true);
        } else {
            // TODO: Cannot do this in this way, take into account asset decimals
            // TODO: Add tests for DAI(18 decimals) and for USDT (6 decimals)
            uint256 tokensToBurn = IporMath.division(
                aaveBalance * 1e18,
                _exchangeRate
            );
            token.burn(msg.sender, tokensToBurn);
            _withdraw(address(aaveStrategy), aaveBalance, true);
        }
    }

    function withdrawAll() external onlyRole(_WITHDRAW_ROLE) {
        _withdraw(_aaveStrategy, IStrategy(_aaveStrategy).balanceOf(), false);
        _withdraw(
            _compoundStrategy,
            IStrategy(_compoundStrategy).balanceOf(),
            false
        );
        IERC20Upgradeable asset = IERC20Upgradeable(_asset);
        uint256 _balance = asset.balanceOf(address(this));
        asset.safeTransfer(msg.sender, _balance);
    }

    /**
     * @dev to migrate all asset from current strategy to another higher apy strategy.
     * @notice only owner can migrate.
     */
    function migrateAssetInMaxApyStrategy()
        external
        onlyRole(_GOVERNANCE_ROLE)
    {
        IStrategy maxApyStrategy = getMaxApyStrategy();
        address from;
        if (address(maxApyStrategy) == _aaveStrategy) {
            from = _compoundStrategy;
            uint256 _shares = IERC20Upgradeable(_compoundShareToken).balanceOf(
                from
            );
            require(_shares > 0, IporErrors.UINT_SHOULD_BE_GRATER_THEN_ZERO);
            IStrategy(_compoundStrategy).withdraw(_shares);
        } else {
            from = _aaveStrategy;
            uint256 _shares = IERC20Upgradeable(_aaveShareToken).balanceOf(
                from
            );
            require(_shares > 0, IporErrors.UINT_SHOULD_BE_GRATER_THEN_ZERO);
            IStrategy(_aaveStrategy).withdraw(_shares);
        }
        uint256 _amount = IERC20Upgradeable(_asset).balanceOf(address(this));
        _deposit(maxApyStrategy, _amount);
        emit MigrateAsset(from, address(maxApyStrategy), _amount);
    }

    /**
     * @dev claim Gov token from current strategy.
     * @notice only owner can claim.
     * @param _account send claimed gove token to _account
     */
    // TODO: Consider to convert _account variable in contract and change fincton to no parameters
    function aaveDoClaim(address _account)
        external
        payable
        onlyRole(_CLAIM_ROLE)
    {
        _doClaim(_account, _aaveStrategy);
    }

    function aaveBeforeClaim(address[] memory assets, uint256 amount)
        external
        payable
        onlyRole(_CLAIM_ROLE)
    {
        IStrategy(_aaveStrategy).beforeClaim(assets, amount);
    }

    // TODO: Consider to convert _account variable in contract and change fincton to no parameters
    function compoundDoClaim(address _account)
        external
        payable
        onlyRole(_CLAIM_ROLE)
    {
        _doClaim(_account, _compoundStrategy);
    }

    // TODO: Consider reorder checks in this way that method will have less calculation (gas opt)
    function _setCompoundStrategy(address strategyAddress) internal {
        require(strategyAddress != address(0), IporErrors.WRONG_ADDRESS);
        IERC20Upgradeable asset = IERC20Upgradeable(_asset);
        IStrategy strategy = IStrategy(strategyAddress);
        IERC20Upgradeable csToken = IERC20Upgradeable(_compoundShareToken);
        if (_compoundStrategy != address(0)) {
            // TODO: safeIncreaseAllowance
            asset.safeApprove(_compoundStrategy, 0);
            csToken.safeApprove(_compoundStrategy, 0);
        }
        address _compoundUnderlyingToken = strategy.getAsset();
        require(
            _compoundUnderlyingToken == address(_asset),
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

        IERC20Upgradeable asset = IERC20Upgradeable(_asset);
        IStrategy strategy = IStrategy(strategyAddress);

        if (_aaveStrategy != address(0)) {
            asset.safeApprove(_aaveStrategy, 0);
            IERC20Upgradeable(_aaveShareToken).safeApprove(_aaveStrategy, 0);
        }
        address _aaveUnderlyingToken = strategy.getAsset();
        require(
            _aaveUnderlyingToken == address(_asset),
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

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(_ADMIN_ROLE)
    {}

    /**
     * @dev to withdraw asset from current strategy.
     * @notice internal method.
     * @param strategyAddress strategy from amount to withdraw
     * @param _amount _amount is interest bearing token like aDAI, cDAI etc.
     */
    function _withdraw(
        address strategyAddress,
        uint256 _amount,
        bool transfer
    ) internal {
        if (_amount != 0) {
            IStrategy(strategyAddress).withdraw(_amount);
            IERC20Upgradeable asset = IERC20Upgradeable(_asset);
            uint256 _balance = asset.balanceOf(address(this));
            if (transfer) {
                asset.safeTransfer(msg.sender, _balance);
            }
            emit Withdraw(strategyAddress, _amount);
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
    function _deposit(IStrategy strategyAddress, uint256 amount) internal {
        IERC20Upgradeable(_asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        strategyAddress.deposit(amount);
    }
}
