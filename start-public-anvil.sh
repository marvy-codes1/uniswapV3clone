#!/bin/bash

# Stop any existing Anvil instances
pkill -f anvil

# Start Anvil in the background
echo "Starting Anvil..."
nohup anvil --host 0.0.0.0 --code-size-limit 50000 > anvil.log 2>&1 &
ANVIL_PID=$!

# Wait for Anvil to start
sleep 3

# Check if Anvil is running
if ! lsof -i :8545 | grep -q LISTEN; then
    echo "Failed to start Anvil"
    exit 1
fi

echo "Anvil started successfully (PID: $ANVIL_PID)"

# Start Cloudflare tunnel
echo "Starting Cloudflare tunnel..."
cloudflared tunnel --url http://localhost:8545 > cloudflared.log 2>&1 &
CLOUDFLARED_PID=$!

# Wait for cloudflared to start
sleep 5

# Get the public URL
PUBLIC_URL=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' cloudflared.log | head -1)

if [ -z "$PUBLIC_URL" ]; then
    echo "Failed to get Cloudflare tunnel URL"
    echo "Check cloudflared.log for details"
    exit 1
fi

echo "================================================"
echo "Anvil is now publicly accessible at:"
echo "$PUBLIC_URL"
echo "================================================"
echo ""
echo "Contract addresses:"
echo "WETH: 0x5FbDB2315678afecb367f032d93F642f64180aa3"
echo "UNI: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"
echo "USDC: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
echo "USDT: 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9"
echo "WBTC: 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9"
echo "Factory: 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707"
echo "Manager: 0x0165878A594ca255338adfa4d48449f69242Eb8F"
echo "Quoter: 0xa513E6E4b8f2a923D98304ec87F64353C4D5C853"
echo ""
echo "Anvil PID: $ANVIL_PID"
echo "Cloudflared PID: $CLOUDFLARED_PID"
echo ""
echo "To stop: pkill -f anvil && pkill -f cloudflared"
