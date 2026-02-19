# 🧠 Uniswap V3 Clone — Deep Dive Implementation

This repository contains my ground-up implementation of the core mechanics behind **Uniswap V3**, inspired by Jeiwan’s book and the original protocol design by Uniswap Labs.

Rather than treating this as a tutorial exercise, I approached it as a protocol engineering and security study — rebuilding the system to deeply understand its mechanics, assumptions, and invariants.

---

## 🔍 What This Project Demonstrates

- Implementation of **concentrated liquidity**
- Tick math and price movement logic
- Liquidity provisioning within custom price ranges
- Swap execution across multiple ticks
- Fee growth accounting
- Precision handling using fixed-point math
- Edge-case handling around price boundaries

---

## 🎯 Why I Built This

I didn’t build this just to “follow a tutorial.”

I built this to:

- Understand AMM mechanics at protocol depth  
- Break down how V3 achieves capital efficiency  
- Explore invariant preservation under complex state transitions  
- Strengthen my smart contract security intuition around liquidity math  

This project required reasoning through:

- Price ↔ Tick conversions  
- Liquidity delta calculations  
- Swap step computation  
- Rounding errors and precision loss  
- State transitions across multiple ticks  

---

## 🧪 Testing & Verification

I wrote tests to validate:

- Swap correctness across liquidity ranges  
- Liquidity accounting invariants  
- Fee accumulation behavior  
- Boundary condition handling  

The goal was not just functionality, but correctness under edge conditions — particularly where precision and state transitions interact.
