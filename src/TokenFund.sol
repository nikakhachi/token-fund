// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./MathHelpers.sol";
import "./DexOperations.sol";
import "openzeppelin/access/AccessControl.sol";
import {ERC20Permit} from "openzeppelin/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "openzeppelin/token/ERC20/extensions/ERC20Votes.sol";

contract TokenFund is
    DexOperations,
    AccessControl,
    ERC20,
    ERC20Permit,
    ERC20Votes
{
    using SafeERC20 for ERC20;

    event ProfitMade(
        address indexed stableCoin,
        uint256 indexed amount,
        uint256 indexed timestamp
    );

    uint16 public immutable profitFee; /// @dev 100 = 1%

    mapping(address => uint256) public initialUSDCDeposits;
    mapping(address => uint256) public initialUSDTDeposits;

    /// @dev This variable is just for DEMONSTRATION Purposes on how the governance works
    /// @dev I'll be using timeLockFunction() in tests to try to vote and execute proposal to make this variable true
    bool public hasProposalExecuted;

    /// @dev Timelock role for governing
    bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE"); /// @dev Role identifier for agents

    constructor(
        address _timelock,
        uint16 _profitFee,
        address _usdc,
        address _usdt,
        address _weth,
        address _link,
        address _uniswapV2Router,
        address _sushiswapRouter
    )
        ERC20("Token Fund Share", "TFS")
        ERC20Permit("Token Fund Share")
        DexOperations(
            _usdc,
            _usdt,
            _weth,
            _link,
            _uniswapV2Router,
            _sushiswapRouter
        )
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(TIMELOCK_ROLE, _timelock);
        profitFee = _profitFee;
    }

    function depositUSDC(uint256 amount) external {
        usdc.safeTransferFrom(msg.sender, address(this), amount);

        uint halfAmount = amount / 2;

        (uint256 wethOut, uint256 linkOut) = _swapForBestPrice(
            halfAmount,
            halfAmount,
            address(usdc),
            address(weth),
            address(usdc),
            address(link)
        );

        initialUSDCDeposits[msg.sender] += amount;

        _mintShares(wethOut, linkOut);
    }

    function depositUSDT(uint256 amount) external {
        usdt.safeTransferFrom(msg.sender, address(this), amount);

        uint halfAmount = amount / 2;

        (uint256 wethOut, uint256 linkOut) = _swapForBestPrice(
            halfAmount,
            halfAmount,
            address(usdt),
            address(weth),
            address(usdt),
            address(link)
        );

        initialUSDTDeposits[msg.sender] += amount;

        _mintShares(wethOut, linkOut);
    }

    function withdrawUSDC() external {
        uint shares = balanceOf(msg.sender);
        uint wethReserve = weth.balanceOf(address(this));
        uint linkReserve = link.balanceOf(address(this));
        uint _totalSupply = totalSupply();

        /// @dev Shares = x△ / x * T = y△ / y * T
        uint wethOut = (shares * wethReserve) / _totalSupply;
        uint linkOut = (shares * linkReserve) / _totalSupply;

        _burn(msg.sender, shares);

        (
            uint256 usdcOutForWethIn,
            uint256 usdcOutForLinkIn
        ) = _swapForBestPrice(
                wethOut,
                linkOut,
                address(weth),
                address(usdc),
                address(link),
                address(usdc)
            );

        uint finalUsdcValue = usdcOutForWethIn + usdcOutForLinkIn;
        uint initialUsdcDeposit = initialUSDCDeposits[msg.sender];

        if (finalUsdcValue > initialUsdcDeposit) {
            uint allProfit = finalUsdcValue - initialUsdcDeposit;
            uint contractProfit = (allProfit * profitFee) / 10000;
            usdc.safeTransfer(
                msg.sender,
                initialUSDCDeposits[msg.sender] + allProfit - contractProfit
            );
            emit ProfitMade(address(usdc), contractProfit, block.timestamp);
        } else {
            usdc.safeTransfer(msg.sender, finalUsdcValue);
        }

        delete initialUSDCDeposits[msg.sender];
    }

    function withdrawUSDT() external {
        uint shares = balanceOf(msg.sender);
        uint wethReserve = weth.balanceOf(address(this));
        uint linkReserve = link.balanceOf(address(this));
        uint _totalSupply = totalSupply();

        /// @dev Shares = x△ / x * T = y△ / y * T
        uint wethOut = (shares * wethReserve) / _totalSupply;
        uint linkOut = (shares * linkReserve) / _totalSupply;

        _burn(msg.sender, shares);

        (
            uint256 usdtOutForWethIn,
            uint256 usdtOutForLinkIn
        ) = _swapForBestPrice(
                wethOut,
                linkOut,
                address(weth),
                address(usdt),
                address(link),
                address(usdt)
            );

        uint finalUsdtValue = usdtOutForWethIn + usdtOutForLinkIn;
        uint initialUsdtDeposit = initialUSDTDeposits[msg.sender];

        if (finalUsdtValue > initialUsdtDeposit) {
            uint allProfit = finalUsdtValue - initialUsdtDeposit;
            uint contractProfit = (allProfit * profitFee) / 10000;
            usdt.safeTransfer(
                msg.sender,
                initialUSDTDeposits[msg.sender] + allProfit - contractProfit
            );
            emit ProfitMade(address(usdt), contractProfit, block.timestamp);
        } else {
            usdt.safeTransfer(msg.sender, finalUsdtValue);
        }

        delete initialUSDTDeposits[msg.sender];
    }

    // /**
    //  * --------------------------------------------------------------------------
    //  * --------------------------------------------------------------------------
    //  * SOME CONTRACT FUNCTIONS THAT WILL INVEST LINK AND WETH TOKENS IN MULTIPLE
    //  * PROTOCOLS AND PROFIT FROM IT
    //  * --------------------------------------------------------------------------
    //  * --------------------------------------------------------------------------
    //  */

    function _mintShares(uint256 wethOut, uint256 linkOut) internal {
        uint256 _totalSupply = totalSupply();
        uint256 shares;
        if (_totalSupply == 0) {
            /// @dev Liquidity/Shares = root from xy
            shares = MathHelpers.sqrt(wethOut * linkOut);
        } else {
            /// @dev Shares = x△ / x * T = y△ / y * T
            shares = MathHelpers.min(
                (wethOut * _totalSupply) / weth.balanceOf(address(this)),
                (linkOut * _totalSupply) / link.balanceOf(address(this))
            );
        }
        _mint(msg.sender, shares);
    }

    /// @dev This function is just for DEMONSTRATION Purposes on how the governance works
    /// @dev I'm using this function in tests to propose, vote and execute proposals
    function timeLockFunction() external onlyRole(TIMELOCK_ROLE) {
        hasProposalExecuted = true;
    }

    // The functions below are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(
        address account,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}
