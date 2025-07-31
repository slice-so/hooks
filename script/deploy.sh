#!/bin/bash
source .env

contractName="$1"

if [ -z "$contractName" ]; then
  output=$(forge script script/Deploy.s.sol --chain base --rpc-url base --private-key $PRIVATE_KEY --verify -vvvv --broadcast --slow)
  
  contractName=$(echo "$output" | grep 'contractName:' | awk -F'"' '{print $2}')
else
  forge script script/Deploy.s.sol --chain base --rpc-url base --private-key $PRIVATE_KEY --sig "run(string memory contractName)" "$contractName" --verify -vvvv --broadcast --slow
fi 

forge script script/WriteAddresses.s.sol --sig "run(string memory contractName)" "$contractName" --chain base --rpc-url base 

echo "Deployed contract: $contractName"