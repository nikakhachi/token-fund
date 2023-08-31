// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./IUniswapV2Router01.sol";
import "forge-std/console.sol";

contract DexOperations {
    using SafeERC20 for ERC20;

    ERC20 public immutable usdc;
    ERC20 public immutable usdt;
    ERC20 public immutable weth;
    ERC20 public immutable link;

    IUniswapV2Router01 public immutable uniswapV2Router;
    IUniswapV2Router01 public immutable sushiswapRouter;

    constructor(
        address _usdc,
        address _usdt,
        address _weth,
        address _link,
        address _uniswapV2Router,
        address _sushiswapRouter
    ) {
        usdc = ERC20(_usdc);
        usdt = ERC20(_usdt);
        weth = ERC20(_weth);
        link = ERC20(_link);
        uniswapV2Router = IUniswapV2Router01(_uniswapV2Router);
        sushiswapRouter = IUniswapV2Router01(_sushiswapRouter);
    }

    /// @param _stableCoin USDT or USDC
    function _getDexPricesForTokens(
        address _stableCoin,
        uint256 _amountIn
    )
        internal
        view
        returns (
            IUniswapV2Router01 dexForWeth,
            IUniswapV2Router01 dexForLink,
            uint256 wethOut,
            uint256 linkOut,
            address[] memory wethPath,
            address[] memory linkPath
        )
    {
        wethPath = new address[](2);
        wethPath[0] = address(_stableCoin);
        wethPath[1] = address(weth);

        uint256 uniswapWethOut = uniswapV2Router.getAmountsOut(
            _amountIn,
            wethPath
        )[1];
        uint256 sushiswapWethOut = sushiswapRouter.getAmountsOut(
            _amountIn,
            wethPath
        )[1];

        linkPath = new address[](2);
        linkPath[0] = address(_stableCoin);
        linkPath[1] = address(link);

        uint256 uniswapLinkOut = uniswapV2Router.getAmountsOut(
            _amountIn,
            linkPath
        )[1];
        uint256 sushiswapLinkOut = sushiswapRouter.getAmountsOut(
            _amountIn,
            linkPath
        )[1];

        if (uniswapWethOut > sushiswapWethOut) {
            wethOut = uniswapWethOut;
            dexForWeth = uniswapV2Router;
        } else {
            wethOut = sushiswapWethOut;
            dexForWeth = sushiswapRouter;
        }

        if (uniswapLinkOut > sushiswapLinkOut) {
            linkOut = uniswapLinkOut;
            dexForLink = uniswapV2Router;
        } else {
            linkOut = sushiswapLinkOut;
            dexForLink = sushiswapRouter;
        }
    }

    /// @param _stableCoin USDT or USDC
    function _getDexPricesForStables(
        address _stableCoin,
        uint256 _wethAmountIn,
        uint256 _linkAmountIn
    )
        internal
        view
        returns (
            IUniswapV2Router01 dexForWeth,
            IUniswapV2Router01 dexForLink,
            uint256 stableOutForWethIn,
            uint256 stableOutForLinkIn,
            address[] memory wethPath,
            address[] memory linkPath
        )
    {
        wethPath = new address[](2);
        wethPath[0] = address(weth);
        wethPath[1] = address(_stableCoin);

        uint256 uniswapStableOutForWethIn = uniswapV2Router.getAmountsOut(
            _wethAmountIn,
            wethPath
        )[1];
        uint256 sushiswapStableOutForWethIn = sushiswapRouter.getAmountsOut(
            _wethAmountIn,
            wethPath
        )[1];

        linkPath = new address[](2);
        linkPath[0] = address(link);
        linkPath[1] = address(_stableCoin);

        uint256 uniswapStableOutForLinkIn = uniswapV2Router.getAmountsOut(
            _linkAmountIn,
            linkPath
        )[1];
        uint256 sushiswapStableOutForLinkIn = sushiswapRouter.getAmountsOut(
            _linkAmountIn,
            linkPath
        )[1];

        if (uniswapStableOutForWethIn > sushiswapStableOutForWethIn) {
            stableOutForWethIn = uniswapStableOutForWethIn;
            dexForWeth = uniswapV2Router;
        } else {
            stableOutForWethIn = sushiswapStableOutForWethIn;
            dexForWeth = sushiswapRouter;
        }

        if (uniswapStableOutForLinkIn > sushiswapStableOutForLinkIn) {
            stableOutForLinkIn = uniswapStableOutForLinkIn;
            dexForLink = uniswapV2Router;
        } else {
            stableOutForLinkIn = sushiswapStableOutForLinkIn;
            dexForLink = sushiswapRouter;
        }
    }

    function _swapTokens(
        ERC20 _stableCoin,
        IUniswapV2Router01 dexForWeth,
        IUniswapV2Router01 dexForLink,
        uint256 amount,
        address[] memory wethPath,
        address[] memory linkPath
    ) internal {
        _stableCoin.safeApprove(address(dexForWeth), amount);
        dexForWeth.swapExactTokensForTokens(
            amount,
            0,
            wethPath,
            address(this),
            block.timestamp
        );

        _stableCoin.safeApprove(address(dexForLink), amount);
        dexForLink.swapExactTokensForTokens(
            amount,
            0,
            linkPath,
            address(this),
            block.timestamp
        );
    }

    function _getStablesInSwap(
        IUniswapV2Router01 dexForWeth,
        IUniswapV2Router01 dexForLink,
        uint256 wethIn,
        uint256 linkIn,
        address[] memory wethPath,
        address[] memory linkPath
    ) internal {
        weth.safeApprove(address(dexForWeth), wethIn);
        dexForWeth.swapExactTokensForTokens(
            wethIn,
            0,
            wethPath,
            address(this),
            block.timestamp
        );

        link.safeApprove(address(dexForLink), linkIn);
        dexForLink.swapExactTokensForTokens(
            linkIn,
            0,
            linkPath,
            address(this),
            block.timestamp
        );
    }
}
