// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./interfaces/IUniswapV3PoolDeployer.sol";

contract UniswapV3Factory is IUniswapV3PoolDeployer {
    mapping(uint24 => bool) public tickSpacings;

    constructor() {
        tickSpacings[10] = true;
        tickSpacings[60] = true;
    }

    function parameters()
        external
        override
        returns (
            address factory,
            address token0,
            address token1,
            uint24 tickSpacing,
            uint24 fee
        )
    {}
}
