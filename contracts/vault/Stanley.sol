// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IPOR/IStrategy.sol";
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
    ExchangeRate
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint8 internal _decimals;
    address internal _asset;

    address private _milton;
    address private _aaveStrategy;
    address private _aaveShareTokens;
    address private _compoundStrategy;
    address private _compoundShareTokens;
    // TODO: _asset -> assetToken

    address private _ivToken;

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
        // TODO: I am using _ only for private method and fields
        address asset,
        address ivToken,
        address aStrategy,
        address cStrategy
    ) public initializer {
        __Ownable_init();
        require(asset != address(0), IporErrors.WRONG_ADDRESS);
        require(ivToken != address(0), IporErrors.WRONG_ADDRESS);

        _asset = asset;
        _decimals = ERC20Upgradeable(asset).decimals();
        _ivToken = ivToken;

        _setAaveStrategy(aStrategy);
        _setCompoundStrategy(cStrategy);
    }

    modifier onlyMilton() {
        require(msg.sender == _milton, IporErrors.CALLER_NOT_MILTON);
        _;
    }

    // Find highest apy strategy to deposit underlying asset
    function getMaxApyStrategy() public view returns (IStrategy depositAsset) {
        IStrategy aave = IStrategy(_aaveStrategy);
        IStrategy compound = IStrategy(_compoundStrategy);
        // TODO: check if use the same number of decimals
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

    function setMilton(address milton) external onlyOwner {
        _milton = milton;
    }

    /**
     * @dev to deposit asset in higher apy strategy.
     * @notice only owner can deposit.
     * @param _amount amount to deposit.
     */
    //  TODO: ADD tests for _amount = 0
    //  TODO: return balanse before deposit
    function deposit(uint256 _amount) external onlyMilton {
        require(_amount != 0, IporErrors.UINT_SHOULD_BE_GRATER_THEN_ZERO);
        IStrategy strategy = getMaxApyStrategy();

        IIvToken token = IIvToken(_ivToken);
        uint256 totalAsset = totalStrategiesBalance();
        uint256 tokenAmount = token.totalSupply();
        uint256 exchangeRate = _calculateExchangeRate(totalAsset, tokenAmount);
        _deposit(strategy, _amount);
        emit Deposit(address(strategy), _amount);

        token.mint(msg.sender, IporMath.division(_amount * 1e18, exchangeRate));
    }

    function setCompoundStrategy(address strategy) external onlyOwner {
        _setCompoundStrategy(strategy);
    }

    function setAaveStrategy(address strategyAddress) external onlyOwner {
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
    function withdraw(uint256 _tokens) external onlyMilton {
        require(_tokens != 0, IporErrors.UINT_SHOULD_BE_GRATER_THEN_ZERO);
        IIvToken token = IIvToken(_ivToken);

        require(
            token.balanceOf(msg.sender) >= _tokens,
            IporErrors.UINT_SHOULD_BE_GRATER_THEN_ZERO
        );

        IStrategy maxApyStrategy = getMaxApyStrategy();

        uint256 _totalAsset = totalStrategiesBalance();
        uint256 _tokenAmount = token.totalSupply();
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
            token.burn(msg.sender, _tokens);
            _withdraw(address(aaveStrategy), amount, true);
            return;
        } else if (amount <= compoundBalance) {
            token.burn(msg.sender, _tokens);
            _withdraw(address(compoundStrategy), amount, true);
            return;
        }
        if (
            address(maxApyStrategy) == _aaveStrategy &&
            amount <= compoundBalance
        ) {
            token.burn(msg.sender, _tokens);
            _withdraw(address(compoundStrategy), amount, true);
            return;
        } else if (amount <= aaveBalance) {
            token.burn(msg.sender, _tokens);
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

    function withdrawAll() external onlyMilton {
        _withdraw(_aaveStrategy, IStrategy(_aaveStrategy).balanceOf(), false);
        _withdraw(
            _compoundStrategy,
            IStrategy(_compoundStrategy).balanceOf(),
            false
        );
        IERC20Upgradeable uToken = IERC20Upgradeable(_asset);
        uint256 _balance = uToken.balanceOf(address(this));
        uToken.safeTransfer(msg.sender, _balance);
    }

    /**
     * @dev to migrate all asset from current strategy to another higher apy strategy.
     * @notice only owner can migrate.
     */
    function migrateAssetInMaxApyStrategy() external onlyOwner {
        IStrategy maxApyStrategy = getMaxApyStrategy();
        address from;
        if (address(maxApyStrategy) == _aaveStrategy) {
            from = _compoundStrategy;
            uint256 _shares = IERC20Upgradeable(_compoundShareTokens).balanceOf(
                from
            );
            require(_shares > 0, IporErrors.UINT_SHOULD_BE_GRATER_THEN_ZERO);
            IStrategy(_compoundStrategy).withdraw(_shares);
        } else {
            from = _aaveStrategy;
            uint256 _shares = IERC20Upgradeable(_aaveShareTokens).balanceOf(
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
        IERC20Upgradeable uToken = IERC20Upgradeable(_asset);
        IStrategy strategy = IStrategy(strategyAddress);
        IERC20Upgradeable csToken = IERC20Upgradeable(_compoundShareTokens);
        if (_compoundStrategy != address(0)) {
            // TODO: safeIncreaseAllowance
            uToken.safeApprove(_compoundStrategy, 0);
            csToken.safeApprove(_compoundStrategy, 0);
        }
        address _compoundUnderlyingToken = strategy.getAsset();
        require(
            _compoundUnderlyingToken == address(_asset),
            IporErrors.UNDERLYINGTOKEN_IS_NOT_COMPATIBLE
        );

        _compoundStrategy = strategyAddress;
        _compoundShareTokens = IStrategy(strategyAddress).shareToken();
        IERC20Upgradeable newCsToken = IERC20Upgradeable(_compoundShareTokens);
        uToken.safeApprove(strategyAddress, 0);
        uToken.safeApprove(strategyAddress, type(uint256).max);
        newCsToken.safeApprove(strategyAddress, 0);
        newCsToken.safeApprove(strategyAddress, type(uint256).max);
        emit SetStrategy(strategyAddress, _compoundShareTokens);
    }

    function _setAaveStrategy(address strategyAddress) internal {
        require(strategyAddress != address(0), IporErrors.WRONG_ADDRESS);
        IERC20Upgradeable uToken = IERC20Upgradeable(_asset);
        IStrategy strategy = IStrategy(strategyAddress);
        if (_aaveStrategy != address(0)) {
            uToken.safeApprove(_aaveStrategy, 0);
            IERC20Upgradeable(_aaveShareTokens).safeApprove(_aaveStrategy, 0);
        }
        address _aaveUnderlyingToken = strategy.getAsset();
        require(
            _aaveUnderlyingToken == address(_asset),
            IporErrors.UNDERLYINGTOKEN_IS_NOT_COMPATIBLE
        );

        _aaveShareTokens = strategy.shareToken();
        IERC20Upgradeable asToken = IERC20Upgradeable(_aaveShareTokens);
        _aaveStrategy = strategyAddress;
        uToken.safeApprove(strategyAddress, 0);
        uToken.safeApprove(strategyAddress, type(uint256).max);
        asToken.safeApprove(strategyAddress, 0);
        asToken.safeApprove(strategyAddress, type(uint256).max);
        emit SetStrategy(strategyAddress, _aaveShareTokens);
    }

    // TODO: this empty ????
    function _authorizeUpgrade(address) internal override onlyOwner {}

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
            IERC20Upgradeable utoken = IERC20Upgradeable(_asset);
            uint256 _balance = utoken.balanceOf(address(this));
            if (transfer) {
                utoken.safeTransfer(msg.sender, _balance);
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
