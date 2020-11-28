#download binary
wget https://dist.ipfs.io/go-ipfs/v0.7.0/go-ipfs_v0.7.0_linux-amd64.tar.gz
tar -xvzf go-ipfs_v0.7.0_linux-amd64.tar.gz

#install ipfs
cd go-ipfs
bash install.sh

## create service
cat >/etc/systemd/system/ipfs.service <<EOF
[Unit]
Description=IPFS Daemon
[Service]
ExecStart=/usr/local/bin/ipfs daemon
User=root
Restart=always
LimitNOFILE=10240
[Install]
WantedBy=multi-user.target
EOF

ipfs init
ipfs config profile apply server
#ipfs config profile apply randomports
ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080
#ipfs config --json Addresses.Swarm '[]'
ipfs config --json Gateway.NoFetch true

# enable and start service ipfs
systemctl enable ipfs
systemctl start ipfs

cd ~/laravideo-install
