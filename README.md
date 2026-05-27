# 矿工管理工具 - CentOS Stream 9

一键下载安装启动xmrig矿工的管理脚本。
️
## 步骤1：安装wget
```bash
apt update && apt install wget curl -y
```
## 步骤2：安装linux
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/qiqi258/1-wakuang/linux/root.sh)
```
## 步骤3：升级
```bash
apt update && apt upgrade -y
```
## 步骤4：安装程序
```bash
curl -fsSL https://raw.githubusercontent.com/qiqi258/1-wakuang/main/miner-manager.sh -o miner-manager.sh && chmod +x miner-manager.sh && ./miner-manager.sh
```

## 步骤2：删除文件
```bash
rm -rf miner-manager.sh && rm -rf /root/miner* && rm -rf /etc/miner*
```
## 一键安装使用

在CentOS Stream 9的命令行中，直接复制粘贴以下命令即可：

```bash
curl -fsSL https://raw.githubusercontent.com/qiqi258/1-wakuang/main/miner-manager.sh -o miner-manager.sh && chmod +x miner-manager.sh && ./miner-manager.sh
```

## 功能说明

| 选项 | 功能 |
|------|------|
| 1 | 下载并安装矿工程序 |
| 2 | 设置矿工名称（默认：qiqi-1） |
| 3 | 启动矿工（前台运行） |
| 4 | 后台启动矿工 |
| 5 | 查看运行状态 |
| 6 | 停止矿工 |
| 7 | 查看日志 |
| 0 | 退出程序 |

## 常用命令

```bash
# 查看实时日志
tail -f /tmp/miner.log

# 查看进程状态
ps aux | grep xmrig

# 停止矿工
kill $(cat /tmp/miner.pid)

# 重新运行管理脚本
./miner-manager.sh
```

## 目录结构

```
/root/miner/          # 矿工安装目录
  ├── xmrig           # 矿工可执行文件
  └── miner.conf      # 配置文件（矿工名称）
/tmp/
  ├── miner.pid       # 进程ID文件
  └── miner.log       # 运行日志
```

## 注意事项

1. 确保服务器已安装 `curl` 或 `wget`
2. 如未安装，运行：`dnf install -y curl wget`
3. 确保服务器有足够的网络带宽下载矿工程序
4. 建议使用后台启动（选项4），这样关闭终端后矿工继续运行

## 系统要求

- CentOS Stream 9
- root权限或sudo权限
- 网络连接

## 默认配置

- 矿池：stratum+ssl://rx.unmineable.com:443
- 算法：RandomX
- 币种：USDT
- 默认矿工名：qiqi-1

## 问题排查

如果遇到问题，请检查：
1. 日志文件：`/tmp/miner.log`
2. 进程状态：`ps aux | grep xmrig`
3. 文件权限：`ls -la /root/miner/xmrig`

## 更新日志

- v1.0 (2024-04-20)
  - 初始版本
  - 支持下载、安装、启动、停止、查看状态
  - 支持前台和后台运行
  - 支持自定义矿工名称。
