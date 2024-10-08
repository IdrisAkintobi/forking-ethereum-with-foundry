# Load environment variables from .env
include .env
export $(shell sed 's/=.*//' .env)

# Formatting and Testing prerequisite
.PHONY: check
check:
	forge fmt
	forge build
	forge test

# Run interaction script
UniswapSwap-interaction: check
	forge script script/UniswapSwap.i.sol --broadcast
