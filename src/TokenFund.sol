// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Math.sol";
import "./DexOperations.sol";

contract TokenFund is ERC20, DexOperations {
    using SafeERC20 for ERC20;

    mapping(address => uint256) public initialUSDCDeposits;
    mapping(address => uint256) public initialUSDTDeposits;

    constructor(
        address _usdc,
        address _usdt,
        address _weth,
        address _link,
        address _uniswapV2Router,
        address _sushiswapRouter
    )
        ERC20("Token Fund Share", "TFS")
        DexOperations(
            _usdc,
            _usdt,
            _weth,
            _link,
            _uniswapV2Router,
            _sushiswapRouter
        )
    {}

    function depositUSDC(uint256 amount) external {
        usdc.safeTransferFrom(msg.sender, address(this), amount);

        uint halfAmount = amount / 2;

        (
            IUniswapV2Router01 dexForWeth,
            IUniswapV2Router01 dexForLink,
            uint256 wethOut,
            uint256 linkOut,
            address[] memory wethPath,
            address[] memory linkPath
        ) = _getDexPricesForTokens(address(usdc), halfAmount);

        _swapTokens(
            usdc,
            dexForWeth,
            dexForLink,
            halfAmount,
            wethPath,
            linkPath
        );

        initialUSDCDeposits[msg.sender] += amount;

        _mintShares(wethOut, linkOut);
    }

    function depositUSDT(uint256 amount) external {
        usdt.safeTransferFrom(msg.sender, address(this), amount);

        uint halfAmount = amount / 2;

        (
            IUniswapV2Router01 dexForWeth,
            IUniswapV2Router01 dexForLink,
            uint256 wethOut,
            uint256 linkOut,
            address[] memory wethPath,
            address[] memory linkPath
        ) = _getDexPricesForTokens(address(usdt), halfAmount);

        _swapTokens(
            usdt,
            dexForWeth,
            dexForLink,
            halfAmount,
            wethPath,
            linkPath
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
            IUniswapV2Router01 dexForWeth,
            IUniswapV2Router01 dexForLink,
            uint256 stableOutForWethIn,
            uint256 stableOutForLinkIn,
            address[] memory wethPath,
            address[] memory linkPath
        ) = _getDexPricesForStables(address(usdc), wethOut, linkOut);

        _getStablesInSwap(
            dexForWeth,
            dexForLink,
            wethOut,
            linkOut,
            wethPath,
            linkPath
        );

        uint finalUsdcValue = stableOutForWethIn + stableOutForLinkIn;

        if (finalUsdcValue > (initialUSDCDeposits[msg.sender] * 110) / 100) {
            uint profit = finalUsdcValue - initialUSDCDeposits[msg.sender];
            usdc.safeTransfer(
                msg.sender,
                initialUSDCDeposits[msg.sender] + (profit * 9) / 10
            );
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
            IUniswapV2Router01 dexForWeth,
            IUniswapV2Router01 dexForLink,
            uint256 stableOutForWethIn,
            uint256 stableOutForLinkIn,
            address[] memory wethPath,
            address[] memory linkPath
        ) = _getDexPricesForStables(address(usdt), wethOut, linkOut);

        _getStablesInSwap(
            dexForWeth,
            dexForLink,
            wethOut,
            linkOut,
            wethPath,
            linkPath
        );

        uint finalUsdtValue = stableOutForWethIn + stableOutForLinkIn;

        if (finalUsdtValue > (initialUSDTDeposits[msg.sender] * 110) / 100) {
            uint profit = finalUsdtValue - initialUSDTDeposits[msg.sender];
            usdt.safeTransfer(
                msg.sender,
                initialUSDTDeposits[msg.sender] + (profit * 9) / 10
            );
        } else {
            usdt.safeTransfer(msg.sender, finalUsdtValue);
        }

        delete initialUSDTDeposits[msg.sender];
    }

    /**
     * --------------------------------------------------------------------------
     * --------------------------------------------------------------------------
     * SOME CONTRACT FUNCTIONS THAT WILL INVEST LINK AND WETH TOKENS IN MULTIPLE
     * PROTOCOLS AND PROFIT FROM IT
     * --------------------------------------------------------------------------
     * --------------------------------------------------------------------------
     */

    function _mintShares(uint256 wethOut, uint256 linkOut) internal {
        uint256 _totalSupply = totalSupply();
        uint256 shares;
        if (_totalSupply == 0) {
            /// @dev Liquidity/Shares = root from xy
            shares = Math.sqrt(wethOut * linkOut);
        } else {
            /// @dev Shares = x△ / x * T = y△ / y * T
            shares = Math.min(
                (wethOut * _totalSupply) / weth.balanceOf(address(this)),
                (linkOut * _totalSupply) / link.balanceOf(address(this))
            );
        }
        _mint(msg.sender, shares);
    }
}
