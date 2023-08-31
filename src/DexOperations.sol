// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./IUniswapV2Router01.sol";
import "forge-std/console.sol";

contract DexOperations {
    using SafeERC20 for IERC20;

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

    function _swapForBestPrice(
        uint256 _amount0In,
        uint256 _amount1In,
        address _token0In,
        address _token0Out,
        address _token1In,
        address _token1Out
    ) internal returns (uint256 token0AmountOut, uint256 token1AmountOut) {
        address[] memory path = new address[](2);
        path[0] = _token0In;
        path[1] = _token0Out;

        uint256 uni0Out = uniswapV2Router.getAmountsOut(_amount0In, path)[1];
        uint256 sushi0Out = sushiswapRouter.getAmountsOut(_amount0In, path)[1];

        if (uni0Out > sushi0Out) {
            token0AmountOut = uni0Out;
            /// @dev We also can set the dex router in variable and then call the swap method
            /// @dev without having to duplicate this approve and swap function but this way it's
            /// @dev more gas efficient for the users
            IERC20(path[0]).safeApprove(address(uniswapV2Router), _amount0In);
            uniswapV2Router.swapExactTokensForTokens(
                _amount0In,
                0,
                path,
                address(this),
                block.timestamp
            );
        } else {
            token0AmountOut = sushi0Out;
            IERC20(path[0]).safeApprove(address(sushiswapRouter), _amount0In);
            sushiswapRouter.swapExactTokensForTokens(
                _amount0In,
                0,
                path,
                address(this),
                block.timestamp
            );
        }

        path[0] = _token1In;
        path[1] = _token1Out;

        uint256 uni1Out = uniswapV2Router.getAmountsOut(_amount1In, path)[1];
        uint256 sushi1Out = sushiswapRouter.getAmountsOut(_amount1In, path)[1];

        if (uni1Out > sushi1Out) {
            token1AmountOut = uni1Out;
            IERC20(path[0]).safeApprove(address(uniswapV2Router), _amount1In);
            uniswapV2Router.swapExactTokensForTokens(
                _amount1In,
                0,
                path,
                address(this),
                block.timestamp
            );
        } else {
            token1AmountOut = sushi1Out;
            IERC20(path[0]).safeApprove(address(sushiswapRouter), _amount1In);
            sushiswapRouter.swapExactTokensForTokens(
                _amount1In,
                0,
                path,
                address(this),
                block.timestamp
            );
        }
    }
}
