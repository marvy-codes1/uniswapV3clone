// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './Math.sol';

library SwapMath {

    // consuming the whole liquidity provided by the range and will move to the next range (if it exists).
    function computeSwapStep(
        uint160 sqrtPriceCurrentX96,
        uint160 sqrtPriceTargetX96,
        uint128 liquidity,
        uint256 amountRemaining
    )
        internal
        pure
        returns (
            uint160 sqrtPriceNextX96,
            uint256 amountIn,
            uint256 amountOut
        ){


            bool zeroForOne = sqrtPriceCurrentX96 >= sqrtPriceTargetX96;
            // sqrtPriceNextX96 = Math.getNextSqrtPriceFromInput(
            //     sqrtPriceCurrentX96,
            //     liquidity,
            //     amountRemaining,
            //     zeroForOne
            // );

            // amountIn = Math.calcAmount0Delta(
            //     sqrtPriceCurrentX96,
            //     sqrtPriceNextX96,
            //     liquidity
            // );

            // amountOut = Math.calcAmount1Delta(
            //     sqrtPriceCurrentX96,
            //     sqrtPriceNextX96,
            //     liquidity
            // );
            amountIn = zeroForOne
                ? Math.calcAmount0Delta(
                    sqrtPriceCurrentX96,
                    sqrtPriceTargetX96,
                    liquidity
                )
                : Math.calcAmount1Delta(
                    sqrtPriceCurrentX96,
                    sqrtPriceTargetX96,
                    liquidity
                );
            if (amountRemaining >= amountIn){ sqrtPriceNextX96 = sqrtPriceTargetX96;
            } else {
                sqrtPriceNextX96 = Math.getNextSqrtPriceFromInput(
                    sqrtPriceCurrentX96,
                    liquidity,
                    amountRemaining,
                    zeroForOne
                );
            }

            amountIn = Math.calcAmount0Delta(
                sqrtPriceCurrentX96,
                sqrtPriceNextX96,
                liquidity
            );
            amountOut = Math.calcAmount1Delta(
                sqrtPriceCurrentX96,
                sqrtPriceNextX96,
                liquidity
            );

            // if (!zeroForOne) {
            //     (amountIn, amountOut) = (amountOut, amountIn);
            // }
        }

}