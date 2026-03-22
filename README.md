# Neo X Consensus Node (Docker)

一键跑Neo X共识节点，挂钱包即可。

## 目录结构

```
neox-consensus/
├── Dockerfile            # 从源码编译 geth v0.5.3
├── docker-compose.yml    # 一键启动
├── entrypoint.sh         # 自动初始化 + 启动
└── node-data/            # 你需要准备的文件 ↓
    ├── keystore/         # 钱包keystore文件（geth格式 UTC--xxx--address）
    ├── password.txt      # 钱包解锁密码（纯文本，一行）
    ├── r1cs/             # (可选) ZK-DKG R1CS 文件
    │   ├── one_message.ccs
    │   ├── two_message.ccs
    │   └── seven_message.ccs
    └── pk/               # (可选) ZK-DKG Proving Key 文件
        ├── one_message.pk
        ├── two_message.pk
        └── seven_message.pk
```

## 快速开始

### 1. 准备钱包

**已有keystore文件：** 直接放到 `node-data/keystore/`

**新建钱包：** 先build再创建
```bash
docker compose build
docker run --rm -v $(pwd)/node-data:/data neox-consensus-neox-consensus \
  geth --datadir /data account new
```

### 2. 写密码文件

```bash
echo "your-password" > node-data/password.txt
chmod 600 node-data/password.txt
```

### 3. (可选) 下载 ZK-DKG 文件

从 https://github.com/bane-labs/mpc 下载 R1CS 和 Proving Key 文件。
没有这些文件节点仍可运行，但无法参与 ZK-DKG 阶段。

### 4. 改公网IP

编辑 `docker-compose.yml`，把 `EXTERNAL_IP` 改成你的服务器公网IP。

### 5. 启动

```bash
docker compose up -d
docker compose logs -f
```

## 成为验证者

跑起来只是共识节点的 watch-only 模式。要成为出块验证者还需要：
1. 通过 Governance 合约注册为 Candidate
2. 获得足够的投票

详见：https://xdocs.ngd.network/governance/governance-in-neo-x

## 常用命令

```bash
# 查看同步状态
docker compose exec neox-consensus geth --datadir /data attach --exec 'eth.syncing'

# 查看区块高度
docker compose exec neox-consensus geth --datadir /data attach --exec 'eth.blockNumber'

# 查看peers
docker compose exec neox-consensus geth --datadir /data attach --exec 'admin.peers.length'

# 查看日志
docker compose logs -f --tail 100

# 停止
docker compose down

# 完全重置（删除链数据，保留钱包）
rm -rf node-data/geth node-data/antimev
```

## 硬件要求

| | 最低 | 推荐 |
|---|---|---|
| CPU | 2核 | 4核+ |
| 内存 | 16GB | 32GB+ |
| 存储 | 200GB SSD | 1TB+ 高性能SSD |
| 网络 | 8Mbps | 25Mbps+ |

## 环境变量

| 变量 | 默认值 | 说明 |
|---|---|---|
| `WALLET_ADDRESS` | 自动检测 | 钱包地址（0x开头），不设会从keystore文件名提取 |
| `EXTERNAL_IP` | 0.0.0.0 | 公网IP，让其他节点能找到你 |
| `MAX_PEERS` | 50 | 最大P2P连接数 |
| `GC_MODE` | archive | `archive`=全量历史 / `full`=省空间 |
| `VERBOSITY` | 3 | 日志级别 (1-5) |
