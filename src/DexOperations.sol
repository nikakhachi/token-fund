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

    function _getDexBestPrices(
        uint256 _amount1In,
        uint256 _amount2In,
        address[] memory _path1,
        address[] memory _path2
    )
        internal
        view
        returns (
            IUniswapV2Router01 dexForToken0,
            IUniswapV2Router01 dexForToken1,
            uint256 token0Out,
            uint256 token1Out
        )
    {
        uint256 uni0Out = uniswapV2Router.getAmountsOut(_amount1In, _path1)[1];
        uint256 sushi0Out = sushiswapRouter.getAmountsOut(_amount1In, _path1)[
            1
        ];

        uint256 uni1Out = uniswapV2Router.getAmountsOut(_amount2In, _path2)[1];
        uint256 sushi1Out = sushiswapRouter.getAmountsOut(_amount2In, _path2)[
            1
        ];

        if (uni0Out > sushi0Out) {
            token0Out = uni0Out;
            dexForToken0 = uniswapV2Router;
        } else {
            token0Out = sushi0Out;
            dexForToken0 = sushiswapRouter;
        }

        if (uni1Out > sushi1Out) {
            token1Out = uni1Out;
            dexForToken1 = uniswapV2Router;
        } else {
            token1Out = sushi1Out;
            dexForToken1 = sushiswapRouter;
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
