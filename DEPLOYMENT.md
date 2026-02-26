# Uniswap V3 Clone - Live Deployment

## Live URLs

- **Frontend**: https://uniswap-v3-clone-1772123400.netlify.app
- **Blockchain RPC**: https://rush-tied-normal-tommy.trycloudflare.com
- **Chain ID**: 31337 (Anvil)

## Contract Addresses

- **WETH**: `0x5FbDB2315678afecb367f032d93F642f64180aa3`
- **UNI**: `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`
- **USDC**: `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`
- **USDT**: `0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9`
- **WBTC**: `0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9`
- **Factory**: `0x5FC8d32690cc91D4c39d9d3abcBD16989F875707`
- **Manager**: `0x0165878A594ca255338adfa4d48449f69242Eb8F`
- **Quoter**: `0xa513E6E4b8f2a923D98304ec87F64353C4D5C853`

## How to Connect with MetaMask

### Step 1: Install MetaMask
Install the MetaMask browser extension from https://metamask.io

### Step 2: Add Custom Network
1. Open MetaMask
2. Click on the network dropdown (top center)
3. Click "Add Network" → "Add a network manually"
4. Fill in the details:
   - **Network Name**: Uniswap V3 Demo (Anvil)
   - **RPC URL**: `https://rush-tied-normal-tommy.trycloudflare.com`
   - **Chain ID**: `31337`
   - **Currency Symbol**: `ETH`
5. Click "Save"

### Step 3: Import Test Account (Pre-funded with Liquidity)
1. In MetaMask, click the account icon (top right)
2. Select "Import Account"
3. Paste this private key:
   ```
   0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
   ```
4. Click "Import"

This account already has:
- 100 ETH
- Tokens (WETH, UNI, USDC, USDT, WBTC)
- Liquidity in all pools

### Step 4: Use the App
1. Go to https://uniswap-v3-clone-1772123400.netlify.app
2. Click "Connect" to connect MetaMask
3. You can now:
   - **Swap tokens** between any available pairs
   - **Add liquidity** to existing pools
   - **Remove liquidity** from positions

## For Developers: Running Locally

### Prerequisites
- Node.js and Yarn
- Foundry (for smart contracts)
- Cloudflared (for public tunnel)

### Start Everything
```bash
# Start Anvil with public access
./start-public-anvil.sh

# The script will:
# 1. Start Anvil on localhost:8545
# 2. Create a Cloudflare tunnel
# 3. Display the public URL
```

### Deploy Contracts
```bash
source .envrc
make deploy
```

### Run UI Locally
```bash
cd ui
yarn install
yarn start
```

### Deploy UI to Netlify
```bash
cd ui
yarn build
netlify deploy --prod --dir=build
```

## Notes

- **Blockchain Host**: The blockchain is hosted locally and exposed via Cloudflare Tunnel
- **Persistence**: The blockchain state is ephemeral (resets when Anvil restarts)
- **Performance**: May be slower than real testnets due to tunnel latency
- **Cost**: Completely free - no gas fees, no faucets needed
- **Cloudflare URL**: The URL changes each time you restart the tunnel. Update the config if needed.

## Keeping the Service Running

To keep Anvil and the tunnel running:
```bash
# Check if running
lsof -i :8545

# View logs
tail -f anvil.log
tail -f cloudflared.log

# Stop services
pkill -f anvil && pkill -f cloudflared
```

## Adding More Liquidity

Users can add liquidity using the "Add liquidity" tab in the UI. They'll need to:
1. Have tokens in their wallet (can be minted from the test account)
2. Approve token spending
3. Specify price range and amounts
4. Confirm the transaction

## Troubleshooting

### "Loading pairs..." stuck
- Check if Anvil is running: `lsof -i :8545`
- Check if cloudflared is running: `ps aux | grep cloudflared`
- Verify tunnel URL is accessible: `curl -X POST https://[YOUR-URL] -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'`

### Network connection issues
- Ensure the RPC URL in MetaMask matches the current tunnel URL
- The Cloudflare tunnel URL changes on restart - update if needed
- Check `cloudflared.log` for the current URL

### Transactions failing
- Ensure you're on the correct network (Chain ID: 31337)
- Check if you have enough ETH for gas
- Import the pre-funded test account if needed
