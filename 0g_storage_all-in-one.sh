#!/bin/bash

show_menu() {
    echo "===== Zstake Storage Node Installation Menu ====="
    echo "1. Install 0g-storage-node"
    echo "2. Update 0g-storage-node"
    echo "3. Turbo Mode(Reset Config.toml & Systemctl)"
    echo "4. Standard Mode(Reset Config.toml & Systemctl)"
    echo "5. Select RPC Endpoint"
    echo "6. Set Miner Key"
    echo "7. Snapshot Install (Standard)"
    echo "8. Node Run & Show Logs"
    echo "9. Exit"
    echo "============================"
}

install_node() {
    echo "Installing 0g-storage-node..."
    rm -r $HOME/0g-storage-node
    sudo apt-get update
    sudo apt-get install -y cargo git clang cmake build-essential openssl pkg-config libssl-dev
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    git clone -b v0.8.7 https://github.com/0glabs/0g-storage-node.git
    cd $HOME/0g-storage-node
    git stash
    git fetch --all --tags
    git checkout be14ba6
    git submodule update --init
    cargo build --release
    rm -rf $HOME/0g-storage-node/run/config.toml
    curl -o $HOME/0g-storage-node/run/config.toml https://raw.githubusercontent.com/zstake-xyz/test/refs/heads/main/0g_storage_turbo.toml
    sudo tee /etc/systemd/system/zgs.service > /dev/null <<EOF
[Unit]
Description=ZGS Node
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/0g-storage-node/run
ExecStart=$HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config.toml
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable zgs
    echo "Installation completed. You can start the service with 'sudo systemctl start zgs'."
}

update_node() {
    echo "Updating 0g-storage-node..."
    sudo systemctl stop zgs
    cp $HOME/0g-storage-node/run/config.toml $HOME/0g-storage-node/run/config.toml.backup
    cd $HOME/0g-storage-node
    git stash
    git fetch --all --tags
    git checkout be14ba6
    git submodule update --init
    cargo build --release
    cp $HOME/0g-storage-node/run/config.toml.backup $HOME/0g-storage-node/run/config.toml
    sudo systemctl daemon-reload
    sudo systemctl enable zgs
    sudo systemctl start zgs
    echo "Node update completed."
}

reset_config_systemctl() {
    echo "Resetting Config.toml and Systemctl (Turbo Mode)..."
    rm -rf $HOME/0g-storage-node/run/config.toml
    curl -o $HOME/0g-storage-node/run/config.toml https://raw.githubusercontent.com/zstake-xyz/test/refs/heads/main/0g_storage_turbo.toml
    sudo tee /etc/systemd/system/zgs.service > /dev/null <<EOF
[Unit]
Description=ZGS Node
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/0g-storage-node/run
ExecStart=$HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config.toml
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable zgs
    echo "Config.toml and Systemctl have been reset to Turbo Mode. You can start the service with 'sudo systemctl start zgs'."
}

standard_mode_reset() {
    echo "Resetting to Standard Mode..."
    rm -rf $HOME/0g-storage-node/run/config.toml
    curl -o $HOME/0g-storage-node/run/config.toml https://raw.githubusercontent.com/zstake-xyz/test/refs/heads/main/0g_storage_config.toml
    echo "Config.toml has been reset to Standard Mode and opened for editing. Please save your changes in nano (Ctrl+O, Enter, Ctrl+X)."
}

select_rpc() {
    echo "Select an RPC Endpoint:"
    echo "1. https://evmrpc-testnet.0g.ai"
    echo "2. https://16600.rpc.thirdweb.com/"
    echo "3. https://rpc.ankr.com/0g_newton"
    echo "4. https://lightnode-json-rpc-0g.grandvalleys.com"
    echo "5. https://0g.bangcode.id"
    echo "6. https://0g-rpc-evm01.validatorvn.com/"
    echo "7. https://og-testnet-jsonrpc.itrocket.net/"
    echo "8. https://0g-evmrpc.zstake.xyz/"
    echo "9. https://0g-rpc.murphynode.net/"
    echo "10. https://0g-api.murphynode.net/"
    echo "11. https://0g-evm-rpc.murphynode.net/"
    echo "12. https://0g.mhclabs.com"
    read -p "Enter your choice (1-3): " rpc_choice
    case $rpc_choice in
        1) rpc="https://evmrpc-testnet.0g.ai" ;;
        2) rpc="https://16600.rpc.thirdweb.com/8d5b0eeb0a8d1eb1cb6ed409464aa4c1" ;;
        3) rpc="https://rpc.ankr.com/0g_newton" ;;
        4) rpc="https://lightnode-json-rpc-0g.grandvalleys.com";;
        5) rpc="https://0g.bangcode.id";;
        6) rpc="https://0g-rpc-evm01.validatorvn.com/";;
        7) rpc="https://og-testnet-jsonrpc.itrocket.net/";;
        8) rpc="https://0g-evmrpc.zstake.xyz/";;
        9) rpc="https://0g-rpc.murphynode.net/";;
        10) rpc="https://0g-api.murphynode.net/";;
        11) rpc="https://0g-evm-rpc.murphynode.net/";;
        12) rpc="https://0g.mhclabs.com";;
        *) echo "Invalid choice. Exiting."; return ;;
    esac
    sed -i "s|^blockchain_rpc_endpoint = .*|blockchain_rpc_endpoint = \"$rpc\"|g" ~/0g-storage-node/run/config.toml
    sudo systemctl stop zgs
    sudo systemctl daemon-reload
    sudo systemctl enable zgs
    echo "RPC Endpoint set to $rpc. You can start the service with 'sudo systemctl start zgs'."
}

set_miner_key() {
    echo "Please enter your Miner Key:"
    read miner_key
    sed -i "s|^miner_key = .*|miner_key = \"$miner_key\"|g" ~/0g-storage-node/run/config.toml
    sudo systemctl daemon-reload
    sudo systemctl enable zgs
    sudo systemctl stop zgs
    sudo systemctl daemon-reload
    sudo systemctl enable zgs
    echo "Miner Key updated. You can start the service with 'sudo systemctl start zgs'."
}

snapshot_install() {
    echo "===== Snapshot Install Menu ====="
    echo "1. Standard Mode Snapshot Install"
    echo "2. Back to Main Menu"
    echo "============================"
    read -p "Select an option (1-2): " snap_choice
    case $snap_choice in
        1) 
            echo "Installing Standard Mode Snapshot..."
            source <(curl -s https://raw.githubusercontent.com/zstake-xyz/test/refs/heads/main/0g_zgs_standard_snapshot.sh)
            echo "Standard Mode Snapshot installation completed."
            ;;
        2) 
            echo "Returning to main menu..."
            return
            ;;
        *) 
            echo "Invalid option. Returning to main menu."
            return
            ;;
    esac
}

show_logs() {
    echo "Displaying logs..."
    sudo systemctl daemon-reload && sudo systemctl enable zgs && sudo systemctl start zgs
    tail -f ~/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d)
}

while true; do
    show_menu
    read -p "Select an option (1-9): " choice
    case $choice in
        1) install_node ;;
        2) update_node ;;
        3) reset_config_systemctl ;;
        4) standard_mode_reset ;;
        5) select_rpc ;;
        6) set_miner_key ;;
        7) snapshot_install ;;
        8) show_logs ;;
        9) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option. Please try again." ;;
    esac
    echo ""
done
