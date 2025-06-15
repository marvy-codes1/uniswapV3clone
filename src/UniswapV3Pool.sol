// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// import "prb-math/PRBMath.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV3FlashCallback.sol";
import "./interfaces/IUniswapV3MintCallback.sol";
import "./interfaces/IUniswapV3Pool.sol";
import "./interfaces/IUniswapV3SwapCallback.sol";

// import "./lib/FixedPoint128.sol";
import "./lib/LiquidityMath.sol";
import "./lib/Math.sol";
// import "./lib/Oracle.sol";
import "./lib/Position.sol";
import "./lib/SwapMath.sol";
import "./lib/Tick.sol";
import "./lib/TickBitmap.sol";
import "./lib/TickMath.sol";

contract UniswapV3Pool {
    using Tick for mapping(int24 => Tick.Info);
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;
    using TickBitmap for mapping(int16 => uint256);

    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    // Pool tokens, immutable
    address public immutable token0;
    address public immutable token1;

    struct SwapState {
        uint256 amountSpecifiedRemaining;
        uint256 amountCalculated;
        uint160 sqrtPriceX96;
        int24 tick;
        uint128 liquidity;
    }

    struct StepState {
       uint160 sqrtPriceStartX96;
        int24 nextTick;
        bool initialized;
        uint160 sqrtPriceNextX96;
        uint256 amountIn;
        uint256 amountOut;
    }

    // adding this so that the manager knows which tokens to mint or swap
    struct CallbackData {
        address token0;
        address token1;
        address payer;
    }
    // Packing variables that are read together
    struct Slot0 {
        // Current sqrt(P)
        uint160 sqrtPriceX96;
        // Current tick
        int24 tick;
    }
    Slot0 public slot0;


    // Amount of liquidity, L.
    uint128 public liquidity;

   
    // Ticks info
    mapping(int24 => Tick.Info) public ticks;
    // Positions info
    // bytes32 is a keccak256 storage of the values in the position, always constant
    mapping(bytes32 => Position.Info) public positions;
    // Tick bitmap
    mapping(int16 => uint256) public tickBitmap;

    // Errors
    error AlreadyInitialized();
    error InsufficientInputAmount();
    error InvalidPriceLimit();
    error InvalidTickRange();
    error NotEnoughLiquidity();
    error ZeroLiquidity();

    // Events
    event Flash(address indexed recipient, uint256 amount0, uint256 amount1);

    event Mint(
        address indexed sender,
        address indexed owner,
        int24 indexed lowerTick,
        int24 upperTick,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    constructor(
        address token0_,
        address token1_,
        uint160 sqrtPriceX96,
        int24 tick
    ) {
        token0 = token0_;
        token1 = token1_;

        slot0 = Slot0({sqrtPriceX96: sqrtPriceX96, tick: tick});
    }


    function mint(
        address owner,
        int24 lowerTick,
        int24 upperTick,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1) {
        // to support price ranges, we need to know whether the CP is below, inside, or above the price range 
        if (
        lowerTick >= upperTick ||
        lowerTick < MIN_TICK ||
        upperTick > MAX_TICK
    ) revert InvalidTickRange();

       if (amount == 0) revert ZeroLiquidity();


        // updating the bitmaping
        bool flippedLower = ticks.update(lowerTick, int128(amount), false);
        bool flippedUpper = ticks.update(upperTick, int128(amount), true);
        if (flippedLower) {
            tickBitmap.flipTick(lowerTick, 1);
        }
        if (flippedUpper) {
            tickBitmap.flipTick(upperTick, 1);
        }

        // ticks.update(lowerTick, amount);
        // ticks.update(upperTick, amount);

        Position.Info storage position = positions.get(
            owner,
            lowerTick,
            upperTick
        );
        position.update(amount);

        // updating amounts to be calcualted automatically instead of hardcoding
        // amount0 = 0.998976618347425280 ether;
        // amount1 = 5000 ether;

        Slot0 memory slot0_ = slot0;

        // amount0 = Math.calcAmount0Delta(
        //     slot0_.sqrtPriceX96,
        //     TickMath.getSqrtRatioAtTick(upperTick),
        //     amount
        // );
        // amount1 = Math.calcAmount1Delta(
        //     slot0_.sqrtPriceX96,
        //     TickMath.getSqrtRatioAtTick(lowerTick),
        //     amount
        // );
        // liquidity += uint128(amount);

        if (slot0_.tick < lowerTick) {
            amount0 = Math.calcAmount0Delta(
                TickMath.getSqrtRatioAtTick(lowerTick),
                TickMath.getSqrtRatioAtTick(upperTick),
                amount
            );
        } else if (slot0_.tick < upperTick) {
            amount0 = Math.calcAmount0Delta(
                slot0_.sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(upperTick),
                amount
            );
            amount1 = Math.calcAmount1Delta(
                slot0_.sqrtPriceX96,
                TickMath.getSqrtRatioAtTick(lowerTick),
                amount
            );
            liquidity = LiquidityMath.addLiquidity(liquidity, int128(amount));
        } else {
            amount1 = Math.calcAmount1Delta(
                TickMath.getSqrtRatioAtTick(lowerTick),
                TickMath.getSqrtRatioAtTick(upperTick),
                amount
            );
        }

        

        uint256 balance0Before;
        uint256 balance1Before;
        if (amount0 > 0) balance0Before = balance0();
        if (amount1 > 0) balance1Before = balance1();

            IUniswapV3MintCallback(msg.sender).uniswapV3MintCallback(
                amount0,
                amount1,
                data
            );

        if (amount0 > 0 && balance0Before + amount0 > balance0())
            revert InsufficientInputAmount();

        if (amount1 > 0 && balance1Before + amount1 > balance1())
            revert InsufficientInputAmount();
        
        emit Mint(msg.sender, owner, lowerTick, upperTick, amount, amount0, amount1);
        }

        
        // ZEROFORONE this variable if true we are going from token x to y and vice-versa
        function swap(address recipient, bool zeroForOne, uint256 amountSpecified, uint160 sqrtPriceLimitX96, bytes calldata data) public returns (int256 amount0, int256 amount1){
            Slot0 memory slot0_ = slot0;
            SwapState memory state = SwapState({
                amountSpecifiedRemaining: amountSpecified,
                amountCalculated: 0,
                sqrtPriceX96: slot0_.sqrtPriceX96,
                tick: slot0_.tick,
                liquidity: liquidity
            });
            // Invalid price limit
            if (
                zeroForOne
                    ? sqrtPriceLimitX96 > slot0_.sqrtPriceX96 ||
                        sqrtPriceLimitX96 < TickMath.MIN_SQRT_RATIO
                    : sqrtPriceLimitX96 < slot0_.sqrtPriceX96 &&
                        sqrtPriceLimitX96 > TickMath.MAX_SQRT_RATIO
            ) revert InvalidPriceLimit();

        // Before filling an order, we initialize a SwapState instance. We’ll loop until amountSpecifiedRemaining is 0
        while (state.amountSpecifiedRemaining > 0 && state.sqrtPriceX96 != sqrtPriceLimitX96) {
            StepState memory step;
            step.sqrtPriceStartX96 = state.sqrtPriceX96;
            (step.nextTick, step.initialized ) = tickBitmap.nextInitializedTickWithinOneWord(
                state.tick,
                1,
                zeroForOne
            );

            step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.nextTick);
            (state.sqrtPriceX96, step.amountIn, step.amountOut) = SwapMath.computeSwapStep(
                state.sqrtPriceX96,
                // ensures no calc outside of sqrtPriceLimitX96
                (
                    zeroForOne
                        ? step.sqrtPriceNextX96 < sqrtPriceLimitX96
                        : step.sqrtPriceNextX96 > sqrtPriceLimitX96
                )
                    ? sqrtPriceLimitX96
                    : step.sqrtPriceNextX96,

                state.liquidity,
                state.amountSpecifiedRemaining
            );
            state.amountSpecifiedRemaining -= step.amountIn;
            state.amountCalculated += step.amountOut;
            state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);

            if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
                if (step.initialized) {
                    int128 liquidityDelta = ticks.cross(step.nextTick);

                    if (zeroForOne) liquidityDelta = -liquidityDelta;

                    state.liquidity = LiquidityMath.addLiquidity(
                        state.liquidity,
                        liquidityDelta
                    );

                    if (state.liquidity == 0) revert NotEnoughLiquidity();
                }
                state.tick = zeroForOne ? step.nextTick - 1 : step.nextTick;
            } else {
                state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
            }

        }
            if (state.tick != slot0_.tick) 
                (slot0.sqrtPriceX96, slot0.tick) = (state.sqrtPriceX96, state.tick);
            
            if (liquidity != state.liquidity) liquidity = state.liquidity;

            (amount0, amount1) = zeroForOne
                ? (
                    int256(amountSpecified - state.amountSpecifiedRemaining),
                    -int256(state.amountCalculated)
                )
                : (
                    -int256(state.amountCalculated),
                    int256(amountSpecified - state.amountSpecifiedRemaining)
            );


            if (zeroForOne) {
                IERC20(token1).transfer(recipient, uint256(-amount1));

                uint256 balance0Before = balance0();
                IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(
                    amount0,
                    amount1,
                    data
                );
                if (balance0Before + uint256(amount0) > balance0())
                    revert InsufficientInputAmount();
            } else {
                IERC20(token0).transfer(recipient, uint256(-amount0));

                uint256 balance1Before = balance1();
                IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(
                    amount0,
                    amount1,
                    data
                );
                if (balance1Before + uint256(amount1) > balance1())
                    revert InsufficientInputAmount();
            }
            // int24 nextTick = 85184;
            // uint160 nextPrice = 5604469350942327889444743441197;
            // amount0 = -0.008396714242162444 ether;
            // amount1 = 42 ether;
            // (slot0.tick, slot0.sqrtPriceX96) = (nextTick, nextPrice);
            // IERC20(token0).transfer(recipient, uint256(-amount0));

            // // uint256 balance1Before = balance1();
            // IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(
            //     amount0,
            //     amount1,
            //     data
            // );
            // if (balance1Before + uint256(amount1) < balance1())
            //     revert InsufficientInputAmount();
            //     emit Swap( msg.sender, recipient, amount0, amount1, slot0.sqrtPriceX96, liquidity, slot0.tick);
        

            }

    function flash(
            uint256 amount0,
            uint256 amount1,
            bytes calldata data
        ) public {
            uint256 balance0Before = IERC20(token0).balanceOf(address(this));
            uint256 balance1Before = IERC20(token1).balanceOf(address(this));

            if (amount0 > 0) IERC20(token0).transfer(msg.sender, amount0);
            if (amount1 > 0) IERC20(token1).transfer(msg.sender, amount1);

            IUniswapV3FlashCallback(msg.sender).uniswapV3FlashCallback(data);

            require(IERC20(token0).balanceOf(address(this)) >= balance0Before);
            require(IERC20(token1).balanceOf(address(this)) >= balance1Before);

            emit Flash(msg.sender, amount0, amount1);
        }
    ////////////////////////////////////////////////////////////////////////////
    //
    // INTERNAL
    //
    ////////////////////////////////////////////////////////////////////////////
    function balance0() internal returns (uint256 balance) {
        balance = IERC20(token0).balanceOf(address(this));
    }

    function balance1() internal returns (uint256 balance) {
        balance = IERC20(token1).balanceOf(address(this));
    }

    function _blockTimestamp() internal view returns (uint32 timestamp) {
        timestamp = uint32(block.timestamp);
    }

}

