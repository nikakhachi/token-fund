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

        address[] memory usdcToWethPath = new address[](2);
        usdcToWethPath[0] = address(usdc);
        usdcToWethPath[1] = address(weth);

        address[] memory usdcToLinkPath = new address[](2);
        usdcToLinkPath[0] = address(usdc);
        usdcToLinkPath[1] = address(link);

        (
            IUniswapV2Router01 dexForWeth,
            IUniswapV2Router01 dexForLink,
            uint256 wethOut,
            uint256 linkOut
        ) = _getDexBestPrices(
                halfAmount,
                halfAmount,
                usdcToWethPath,
                usdcToLinkPath
            );

        _swapTokens(
            usdc,
            dexForWeth,
            dexForLink,
            halfAmount,
            usdcToWethPath,
            usdcToLinkPath
        );

        initialUSDCDeposits[msg.sender] += amount;

        _mintShares(wethOut, linkOut);
    }

    function depositUSDT(uint256 amount) external {
        usdt.safeTransferFrom(msg.sender, address(this), amount);

        uint halfAmount = amount / 2;

        address[] memory usdtToWethPath = new address[](2);
        usdtToWethPath[0] = address(usdt);
        usdtToWethPath[1] = address(weth);

        address[] memory usdtToLinkPath = new address[](2);
        usdtToLinkPath[0] = address(usdt);
        usdtToLinkPath[1] = address(link);

        (
            IUniswapV2Router01 dexForWeth,
            IUniswapV2Router01 dexForLink,
            uint256 wethOut,
            uint256 linkOut
        ) = _getDexBestPrices(
                halfAmount,
                halfAmount,
                usdtToWethPath,
                usdtToLinkPath
            );

        _swapTokens(
            usdt,
            dexForWeth,
            dexForLink,
            halfAmount,
            usdtToWethPath,
            usdtToLinkPath
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

        address[] memory wethToUsdcPath = new address[](2);
        wethToUsdcPath[0] = address(weth);
        wethToUsdcPath[1] = address(usdc);

        address[] memory linkToUsdcPath = new address[](2);
        linkToUsdcPath[0] = address(link);
        linkToUsdcPath[1] = address(usdc);

        (
            IUniswapV2Router01 dexForWethToUsdc,
            IUniswapV2Router01 dexForLinkToUsdc,
            uint256 usdcOutForWethIn,
            uint256 usdcOutForLinkIn
        ) = _getDexBestPrices(wethOut, linkOut, wethToUsdcPath, linkToUsdcPath);

        _getStablesInSwap(
            dexForWethToUsdc,
            dexForLinkToUsdc,
            wethOut,
            linkOut,
            wethToUsdcPath,
            linkToUsdcPath
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

        console.log(linkReserve);

        /// @dev Shares = x△ / x * T = y△ / y * T
        uint wethOut = (shares * wethReserve) / _totalSupply;
        uint linkOut = (shares * linkReserve) / _totalSupply;

        _burn(msg.sender, shares);

        address[] memory wethToUsdtPath = new address[](2);
        wethToUsdtPath[0] = address(weth);
        wethToUsdtPath[1] = address(usdt);

        address[] memory linkToUsdtPath = new address[](2);
        linkToUsdtPath[0] = address(link);
        linkToUsdtPath[1] = address(usdt);

        (
            IUniswapV2Router01 dexForWethToUsdt,
            IUniswapV2Router01 dexForLinkToUsdt,
            uint256 usdtOutForWethIn,
            uint256 usdtOutForLinkIn
        ) = _getDexBestPrices(wethOut, linkOut, wethToUsdtPath, linkToUsdtPath);

        _getStablesInSwap(
            dexForWethToUsdt,
            dexForLinkToUsdt,
            wethOut,
            linkOut,
            wethToUsdtPath,
            linkToUsdtPath
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
