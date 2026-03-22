# Neo X Consensus Node (Docker)

Docker一键跑Neo X主网共识节点。基于 [bane-labs/go-ethereum](https://github.com/bane-labs/go-ethereum) v0.5.3 源码编译。

## 快速开始

```bash
git clone https://github.com/jusaka/neox-consensus-docker.git
cd neox-consensus-docker

# 1. 构建镜像
docker compose build

# 2. 创建钱包（或直接放已有keystore到 node-data/keystore/）
docker run --rm --entrypoint geth -v $(pwd)/node-data:/data \
  neox-consensus-docker-neox-consensus --datadir /data account new

# 3. 写密码文件
echo "your-password" > node-data/password.txt
chmod 600 node-data/password.txt

# 4. 启动
docker compose up -d
docker compose logs -f
```

## 目录结构

```
node-data/
├── keystore/              # 钱包文件（geth格式）
├── password.txt           # 解锁密码
├── r1cs/                  # (可选) ZK-DKG R1CS，从 github.com/bane-labs/mpc 下载
│   ├── one_message.ccs
│   ├── two_message.ccs
│   └── seven_message.ccs
└── pk/                    # (可选) ZK-DKG Proving Key
    ├── one_message.pk
    ├── two_message.pk
    └── seven_message.pk
```

## 环境变量

| 变量 | 默认值 | 说明 |
|---|---|---|
| `WALLET_ADDRESS` | 自动从keystore提取 | 钱包地址 |
| `EXTERNAL_IP` | `0.0.0.0` | 公网IP |
| `BOOTNODES` | 官方主网节点 | 自定义bootnode |
| `MAX_PEERS` | `50` | 最大连接数 |
| `GC_MODE` | `archive` | `archive`全量 / `full`省空间 |
| `VERBOSITY` | `3` | 日志级别 1-5 |

## 常用命令

```bash
# 同步状态
docker compose exec neox-consensus geth --datadir /data attach --exec 'eth.syncing'

# 区块高度
docker compose exec neox-consensus geth --datadir /data attach --exec 'eth.blockNumber'

# peers数量
docker compose exec neox-consensus geth --datadir /data attach --exec 'admin.peers.length'

# 停止 / 重置链数据
docker compose down
rm -rf node-data/geth node-data/antimev
```

## 端口

| 端口 | 用途 |
|---|---|
| 30303 | P2P (TCP+UDP) |
| 8545 | HTTP RPC |
| 8546 | WebSocket |
| 8551 | Auth RPC |

## 成为验证者

启动后默认是 watch-only 模式。要出块需要：
1. 通过 [Governance合约](https://xdocs.ngd.network/governance/governance-in-neo-x) 注册为 Candidate
2. 获得足够投票

## 硬件要求

最低 2核/16GB/200GB SSD/8Mbps，推荐 4核+/32GB+/1TB+ SSD/25Mbps+

## 网络信息

- Chain ID: `47763`
- Network: Neo X Mainnet
- Consensus: dBFT + AMEV + ZK-DKG
