.PHONY: test

anvil:
	anvil --code-size-limit 50000

deploy:
	forge script scripts/DeployDevelopment.s.sol --broadcast --fork-url $$ETH_RPC_URL --private-key $$PRIVATE_KEY --code-size-limit 50000

deploy-sepolia:
	FOUNDRY_PROFILE=sepolia forge script scripts/DeploySepolia.s.sol --broadcast --fork-url $$SEPOLIA_RPC_URL --private-key $$SEPOLIA_PRIVATE_KEY --legacy

update-abis:
	forge inspect UniswapV3Factory abi > ui/src/abi/Factory.json
	forge inspect UniswapV3Manager abi > ui/src/abi/Manager.json
	forge inspect UniswapV3Pool abi > ui/src/abi/Pool.json
	forge inspect UniswapV3Quoter abi > ui/src/abi/Quoter.json

test:
	forge test --ffi