while true; do 
    response=$(curl -s -X POST http://localhost:5678 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"zgs_getStatus","params":[],"id":1}')
    logSyncHeight=$(echo $response | jq '.result.logSyncHeight')
    connectedPeers=$(echo $response | jq '.result.connectedPeers')
    network_height=$(curl -s https://og-testnet-rpc.itrocket.net/status | jq -r '.result.sync_info.latest_block_height')
    Block_Left=$((network_height - logSyncHeight))
    echo -e "Network Height: \033[33m$network_height\033[0m, Block: \033[32m$logSyncHeight\033[0m, Diff: \033[31m$Block_Left\033[0m, Peers: \033[34m$connectedPeers\033[0m"
    sleep 5; 
done
