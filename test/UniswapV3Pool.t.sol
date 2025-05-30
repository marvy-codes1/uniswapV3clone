// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "forge-std/Test.sol";
import "./ERC20Mintable.sol";
import "../src/UniswapV3Pool.sol";

// to start testing you have to import all required contracts

contract UniswapV3PoolTest is Test {
    ERC20Mintable token0;
    ERC20Mintable token1;
    UniswapV3Pool pool;

    bool public shouldTransferInCallback;

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
        bool shouldTransferInCallback;

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
        shouldTransferInCallback = params.shouldTransferInCallback;
        if (params.mintLiqudity) {

            (poolBalance0, poolBalance1) = pool.mint(
                address(this),
                params.lowerTick,
                params.upperTick,
                params.liquidity
            );
        }
        
    }

        function testMintSuccess() public {
            TestCaseParams memory params = TestCaseParams({
                wethBalance: 1 ether,
                usdcBalance: 5000 ether,
                currentTick: 85176,
                lowerTick: 84222,
                upperTick: 86129,
                liquidity: 1517882343751509868544,
                currentSqrtP: 5602277097478614198912276234240,
                transferInMintCallback: true,
                transferInSwapCallback: true,
                shouldTransferInCallback: true,
                mintLiqudity: true
        });
            (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);
            uint256 expectedAmount0 = 0.998976618347425280 ether;
            uint256 expectedAmount1 = 5000 ether;
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
            ////////
            assertEq(token0.balanceOf(address(pool)), expectedAmount0);
            assertEq(token1.balanceOf(address(pool)), expectedAmount1);

            
       
        }
        /*
         //
        
        //
        (bool tickInitialized, uint128 tickLiquidity) = pool.ticks(
            params.lowerTick
        );
        assertTrue(tickInitialized);
        assertEq(tickLiquidity, params.liquidity);
        //
        (tickInitialized, tickLiquidity) = pool.ticks(params.upperTick);
        assertTrue(tickInitialized);
        assertEq(tickLiquidity, params.liquidity);
        */



    function uniswapV3MintCallback(uint256 amount0, uint256 amount1) public {
        if (shouldTransferInCallback) {
            token0.transfer(msg.sender, amount0);
            token1.transfer(msg.sender, amount1);
        }
    }


}