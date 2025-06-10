// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "./ERC20Mintable.sol";
import "../src/UniswapV3Pool.sol";
import "./TestUtils.sol";
// to start testing you have to import all required contracts

contract UniswapV3PoolTest is Test {
    ERC20Mintable token0;
    ERC20Mintable token1;
    UniswapV3Pool pool;

    bool public shouldTransferInCallback;
    bool transferInMintCallback = true;
    bool transferInSwapCallback = true;

    struct TestCaseParams {
        uint256 wethBalance;
        uint256 usdcBalance;
        int24 currentTick;
        int24 lowerTick;
        int24 upperTick;
        uint128 liquidity;
        uint160 currentSqrtP;
        bool transferInMintCallback;
        bool transferInSwapCallback;
        bool mintLiqudity;
    }

    function setUp() public {
        token0 = new ERC20Mintable("Ether", "ETH", 18);
        token1 = new ERC20Mintable("USDC", "USDC", 18);
    }

 function setupTestCase(TestCaseParams memory params)
        internal
        returns (uint256 poolBalance0, uint256 poolBalance1)
    {
        token0.mint(address(this), params.wethBalance);
        token1.mint(address(this), params.usdcBalance);

        pool = new UniswapV3Pool(
            address(token0),
            address(token1),
            params.currentSqrtP,
            params.currentTick
        );

        if (params.mintLiqudity) {
            token0.approve(address(this), params.wethBalance);
            token1.approve(address(this), params.usdcBalance);

            bytes memory extra = TestUtils.encodeExtra(
                address(token0),
                address(token1),
                address(this)
            );

            (poolBalance0, poolBalance1) = pool.mint(
                address(this),
                params.lowerTick,
                params.upperTick,
                params.liquidity,
                extra
            );
        }

        transferInMintCallback = params.transferInMintCallback;
        transferInSwapCallback = params.transferInSwapCallback;
    }


     function testMintSuccess() public {
            TestCaseParams memory params = TestCaseParams({
                wethBalance: 1 ether,
                usdcBalance: 5001 ether,
                currentTick: 85176,
                lowerTick: 84222,
                upperTick: 86129,
                liquidity: 1517882343751509868544,
                currentSqrtP: 5602277097478614198912276234240,
                transferInMintCallback: true,
                transferInSwapCallback: true,
                mintLiqudity: true
        });
            (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);
            uint256 expectedAmount0 = 0.998628802115141959 ether;
        uint256 expectedAmount1 = 5000.209190920489524100 ether;
            assertEq(
                poolBalance0,
                expectedAmount0,
                "incorrect token0 deposited amount"
            );
            assertEq(
                poolBalance1,
                expectedAmount1,
                "incorrect token1 deposited amount"
            );
            // we expect specific precalculated amount
            assertEq(token0.balanceOf(address(pool)), expectedAmount0);
            assertEq(token1.balanceOf(address(pool)), expectedAmount1);

            // we need to check the position the pool created for us:: keys in positions mapping is a has
            bytes32 positionKey = keccak256(
                abi.encodePacked(address(this), params.lowerTick, params.upperTick)
            );
            uint128 posLiquidity = pool.positions(positionKey);
                assertEq(posLiquidity, params.liquidity);

            // Next, come the ticks. Again, it’s straightforward:
            (bool tickInitialized, uint128 tickLiquidity) = pool.ticks(
                params.lowerTick
            );
                assertTrue(tickInitialized);
                assertEq(tickLiquidity, params.liquidity);
            (tickInitialized, tickLiquidity) = pool.ticks(params.upperTick);
                assertTrue(tickInitialized);
                assertEq(tickLiquidity, params.liquidity);
            // And finally, √p and L
            (uint160 sqrtPriceX96, int24 tick) = pool.slot0();
                assertEq(
                    sqrtPriceX96,
                    5602277097478614198912276234240,
                    "invalid current sqrtP"
                );
                assertEq(tick, 85176, "invalid current tick");
                assertEq(
                    pool.liquidity(),
                    1517882343751509868544,
                    "invalid current liquidity"
                );

}


  function testSwapBuyEth() public {
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5001 ether,
            currentTick: 85176,
            lowerTick: 84222,
            upperTick: 86129,
            liquidity: 1517882343751509868544,
            currentSqrtP: 5602277097478614198912276234240,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiqudity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        uint256 swapAmount = 42 ether; // 42 USDC
        token1.mint(address(this), swapAmount);
        token1.approve(address(this), swapAmount);

        bytes memory extra = TestUtils.encodeExtra(
            address(token0),
            address(token1),
            address(this)
        );

        int256 userBalance0Before = int256(token0.balanceOf(address(this)));
        int256 userBalance1Before = int256(token1.balanceOf(address(this)));

        (int256 amount0Delta, int256 amount1Delta) = pool.swap(
            address(this),
            false,
            swapAmount,
            extra
        );

        assertEq(amount0Delta, -0.008396714242162445 ether, "invalid ETH out");
        assertEq(amount1Delta, 42 ether, "invalid USDC in");

        assertEq(
            token0.balanceOf(address(this)),
            uint256(userBalance0Before - amount0Delta),
            "invalid user ETH balance"
        );
        assertEq(
            token1.balanceOf(address(this)),
            uint256(userBalance1Before - amount1Delta),
            "invalid user USDC balance"
        );

        assertEq(
            token0.balanceOf(address(pool)),
            uint256(int256(poolBalance0) + amount0Delta),
            "invalid pool ETH balance"
        );
        assertEq(
            token1.balanceOf(address(pool)),
            uint256(int256(poolBalance1) + amount1Delta),
            "invalid pool USDC balance"
        );

        (uint160 sqrtPriceX96, int24 tick) = pool.slot0();
        assertEq(
            sqrtPriceX96,
            5604469350942327889444743441197,
            "invalid current sqrtP"
        );
        assertEq(tick, 85184, "invalid current tick");
        assertEq(
            pool.liquidity(),
            1517882343751509868544,
            "invalid current liquidity"
        );
    }

   


    ////////////////////////////////////////////////////////////////////////////
    //
    // CALLBACKS
    //
    ////////////////////////////////////////////////////////////////////////////
    function uniswapV3SwapCallback(
        int256 amount0,
        int256 amount1,
        bytes calldata data
    ) public {
        if (transferInSwapCallback) {
            UniswapV3Pool.CallbackData memory extra = abi.decode(
                data,
                (UniswapV3Pool.CallbackData)
            );

            if (amount0 > 0) {
                IERC20(extra.token0).transferFrom(
                    extra.payer,
                    msg.sender,
                    uint256(amount0)
                );
            }

            if (amount1 > 0) {
                IERC20(extra.token1).transferFrom(
                    extra.payer,
                    msg.sender,
                    uint256(amount1)
                );
            }
        }
    }

    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) public {
        if (transferInMintCallback) {
            UniswapV3Pool.CallbackData memory extra = abi.decode(
                data,
                (UniswapV3Pool.CallbackData)
            );

            IERC20(extra.token0).transferFrom(extra.payer, msg.sender, amount0);
            IERC20(extra.token1).transferFrom(extra.payer, msg.sender, amount1);
        }
    }

}