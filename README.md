# Uniswap V3 Clone - Live Demo

<div align="center">

**🚀 [Live Demo](https://uniswap-v3-clone-1772123400.netlify.app) | 📖 [Full Documentation](./DEPLOYMENT.md)**

![Front-end application screenshot](/screenshot.png)

A fully functional Uniswap V3 decentralized exchange clone with concentrated liquidity, built from scratch for educational purposes.

</div>

---

## ✨ Features

- 🔄 **Token Swaps** - Multi-hop swaps with automatic path finding
- 💧 **Liquidity Provision** - Add/remove liquidity with concentrated positions
- 📊 **Real-time Price Quotes** - On-chain price calculations
- 🎯 **Slippage Protection** - Configurable slippage tolerance
- 🔗 **Live Blockchain** - Publicly accessible testnet via Cloudflare Tunnel

## 🌐 Try It Live (No Setup Required!)

**Live App**: https://uniswap-v3-clone-1772123400.netlify.app

### Quick Start (2 minutes)

1. **Install MetaMask** - [Get it here](https://metamask.io)

2. **Add Custom Network**
   - Network Name: `Uniswap V3 Demo`
   - RPC URL: `https://rush-tied-normal-tommy.trycloudflare.com`
   - Chain ID: `31337`
   - Currency: `ETH`

3. **Import Test Account** (Pre-funded with tokens & liquidity)
   ```
   Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
   ```

4. **Start Trading!** 🎉
   - Swap between WETH, USDC, UNI, WBTC, USDT
   - Add liquidity to earn fees
   - Remove liquidity anytime

## 🛠️ Tech Stack

- **Smart Contracts**: Solidity, Foundry
- **Frontend**: React, ethers.js, TailwindCSS
- **Blockchain**: Anvil (local Ethereum node)
- **Deployment**: Netlify (UI), Cloudflare Tunnel (Blockchain)

## 📦 Contract Addresses

| Contract | Address |
|----------|----------|
| Factory  | `0x5FC8d32690cc91D4c39d9d3abcBD16989F875707` |
| Manager  | `0x0165878A594ca255338adfa4d48449f69242Eb8F` |
| Quoter   | `0xa513E6E4b8f2a923D98304ec87F64353C4D5C853` |
| WETH     | `0x5FbDB2315678afecb367f032d93F642f64180aa3` |
| USDC     | `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512` |
| UNI      | `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0` |
| WBTC     | `0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9` |
| USDT     | `0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9` |

## 🚀 Run Locally

### Prerequisites
- Node.js (v16+) and Yarn
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Cloudflared](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/)

### Setup

```bash
# Clone the repository
git clone https://github.com/marvy-codes1/uniswapV3clone.git
cd uniswapV3clone

# Install smart contract dependencies
forge install

# Install UI dependencies
cd ui && yarn install && cd ..

# Start Anvil with public access
./start-public-anvil.sh

# Deploy contracts (in a new terminal)
source .envrc
make deploy

# Start the UI (in a new terminal)
cd ui && yarn start
```

The app will open at `http://localhost:3000`

## 📚 How It Works

### Concentrated Liquidity
Unlike Uniswap V2, liquidity providers can concentrate their capital within specific price ranges, earning more fees with less capital.

### Multi-hop Swaps
The app automatically finds the best path for your swap, even across multiple pools (e.g., WETH → USDC → UNI).

### On-chain Quotes
Price quotes are calculated on-chain using the Quoter contract, ensuring accuracy before you swap.

## 🤝 Contributing

This is an educational project. Feel free to:
- Report bugs
- Suggest improvements
- Fork and experiment

## 📄 License

MIT License - See [LICENSE](./LICENSE) for details

Based on the excellent [Uniswap V3 Development Book](https://uniswapv3book.com) by Jeiwan.

## 🙏 Acknowledgments

- [Uniswap V3 Development Book](https://uniswapv3book.com) - Educational resource
- [Foundry](https://book.getfoundry.sh/) - Smart contract development toolkit
- [Cloudflare Tunnel](https://www.cloudflare.com/products/tunnel/) - Public blockchain access

---

<div align="center">

**Built with ❤️ for the Web3 community**

Questions? Open an issue or reach out!

</div>
