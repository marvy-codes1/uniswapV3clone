// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "../src/UniswapV3Pool.sol";
import "../src/interfaces/IERC20.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV3Pool.sol";
import "./interfaces/IUniswapV3Manager.sol";
import "./lib/LiquidityMath.sol";
import "./lib/TickMath.sol";

contract UniswapV3Manager {
    error SlippageCheckFailed(uint256 amount0, uint256 amount1);

    struct MintParams {
        address poolAddress;
        int24 lowerTick;
        int24 upperTick;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
    }

    function mint(
        // address poolAddress_,
        // int24 lowerTick,
        // int24 upperTick,
        // uint128 liquidity,
        // bytes calldata data
        MintParams calldata params
    ) public returns (uint256 amount0, uint256 amount1) {

        IUniswapV3Pool pool = IUniswapV3Pool(params.poolAddress);
        (uint160 sqrtPriceX96, ) = pool.slot0();
        uint160 sqrtPriceLowerX96 = TickMath.getSqrtRatioAtTick(
            params.lowerTick
        );
        uint160 sqrtPriceUpperX96 = TickMath.getSqrtRatioAtTick(
            params.upperTick
        );

        uint128 liquidity = LiquidityMath.getLiquidityForAmounts(
            sqrtPriceX96,
            sqrtPriceLowerX96,
            sqrtPriceUpperX96,
            params.amount0Desired,
            params.amount1Desired
        );


        // UniswapV3Pool(poolAddress_).mint(
        //     msg.sender,
        //     lowerTick,
        //     upperTick,
        //     liquidity,
        //     data
        // );

        (amount0, amount1) = pool.mint(
            msg.sender,
            params.lowerTick,
            params.upperTick,
            liquidity,
            abi.encode(
                IUniswapV3Pool.CallbackData({
                    token0: pool.token0(),
                    token1: pool.token1(),
                    payer: msg.sender
                })
        )
        );

        if (amount0 < params.amount0Min || amount1 < params.amount1Min)
            revert SlippageCheckFailed(amount0, amount1);
        }

       function swap(
        address poolAddress_,
        bool zeroForOne,
        uint256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) public returns (int256, int256) {
        return
            IUniswapV3Pool(poolAddress_).swap(
                msg.sender,
                zeroForOne,
                amountSpecified,
                sqrtPriceLimitX96 == 0
                    ? (
                        zeroForOne
                            ? TickMath.MIN_SQRT_RATIO + 1
                            : TickMath.MAX_SQRT_RATIO - 1
                    )
                    : sqrtPriceLimitX96,
                data
            );
    }

    
    function uniswapV3MintCallback(uint256 amount0, uint256 amount1, bytes calldata data) public {
            UniswapV3Pool.CallbackData memory extra = abi.decode(
                data,
                (UniswapV3Pool.CallbackData)
            );
            IERC20(extra.token0).transferFrom(extra.payer, msg.sender, amount0);
            IERC20(extra.token1).transferFrom(extra.payer, msg.sender, amount1);
    }

    // amounts during a swap can be positive and negative(taken from the pool) we only need the callback amount
    function uniswapV3SwapCallback(int256 amount0, int256 amount1,  bytes calldata data) public {
        UniswapV3Pool.CallbackData memory extra = abi.decode(
                data,
                (UniswapV3Pool.CallbackData)
            );
        if (amount0 > 0) {
            IERC20(extra.token0).transferFrom(extra.payer, msg.sender, uint256(amount0));
        }
        if (amount1 > 0) {
           IERC20(extra.token1).transferFrom(extra.payer, msg.sender, uint256(amount1));
        }
    }
}
