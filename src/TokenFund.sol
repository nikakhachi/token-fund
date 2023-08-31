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
