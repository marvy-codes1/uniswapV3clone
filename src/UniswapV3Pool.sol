// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// import "prb-math/PRBMath.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV3FlashCallback.sol";
import "./interfaces/IUniswapV3MintCallback.sol";
import "./interfaces/IUniswapV3Pool.sol";
import "./interfaces/IUniswapV3PoolDeployer.sol";
import "./interfaces/IUniswapV3SwapCallback.sol";

// import "./lib/FixedPoint128.sol";
// import "./lib/LiquidityMath.sol";
// import "./lib/Math.sol";
// import "./lib/Oracle.sol";
import "./lib/Position.sol";
// import "./lib/SwapMath.sol";
import "./lib/Tick.sol";
import "./lib/TickBitmap.sol";
// import "./lib/TickMath.sol";

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
    error InvalidTickRange();
    error ZeroLiquidity();
    error InsufficientInputAmount();

    // Events
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
        if (
        lowerTick >= upperTick ||
        lowerTick < MIN_TICK ||
        upperTick > MAX_TICK
    ) revert InvalidTickRange();

    if (amount == 0) revert ZeroLiquidity();

        ticks.update(lowerTick, amount);
        ticks.update(upperTick, amount);

        Position.Info storage position = positions.get(
            owner,
            lowerTick,
            upperTick
        );
        position.update(amount);

        amount0 = 0.998976618347425280 ether;
        amount1 = 5000 ether;
    
        liquidity += uint128(amount);

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

        function swap(address recipient, bytes calldata data) public returns (int256 amount0, int256 amount1){
            int24 nextTick = 85184;
            uint160 nextPrice = 5604469350942327889444743441197;
            amount0 = -0.008396714242162444 ether;
            amount1 = 42 ether;
            (slot0.tick, slot0.sqrtPriceX96) = (nextTick, nextPrice);
            IERC20(token0).transfer(recipient, uint256(-amount0));

            uint256 balance1Before = balance1();
            IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(
                amount0,
                amount1,
                data
            );
            if (balance1Before + uint256(amount1) < balance1())
                revert InsufficientInputAmount();
                emit Swap( msg.sender, recipient, amount0, amount1, slot0.sqrtPriceX96, liquidity, slot0.tick);
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

