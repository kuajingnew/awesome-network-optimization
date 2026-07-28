#!/bin/bash
# ==============================================================
# awesome-network-optimization 数据同步脚本
# 
# 用法: 
#   1. 配置 API 地址:  export API_BASE_URL="https://tochick.xyz"
#   2. 运行:          ./scripts/sync-data.sh
#
# 效果: 
#   从 API 拉取最新数据 → 更新 JSON 缓存 → git commit & push
# ==============================================================

set -e

REPO_DIR="/root/awesome-network-optimization"
DATA_DIR="$REPO_DIR/_data"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 检查 API 地址是否已配置
if [ -z "$API_BASE_URL" ]; then
    # 从本地配置文件读取（该文件不在仓库中）
    CONFIG_FILE="$REPO_DIR/.api-config"
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        echo "[ERROR] API_BASE_URL 未设置"
        echo "请先执行: export API_BASE_URL=\"https://你的域名\""
        echo "或创建 $CONFIG_FILE 文件，内容为: API_BASE_URL=\"https://你的域名\""
        exit 1
    fi
fi

echo "=== 开始同步数据: $TIMESTAMP ==="

# 创建数据目录
mkdir -p "$DATA_DIR"

# 拉取机场数据
echo ">>> 拉取机场数据..."
AIRPORT_RESP=$(curl -s -w "\n%{http_code}" "$API_BASE_URL/api/public/links/airport")
AIRPORT_HTTP_CODE=$(echo "$AIRPORT_RESP" | tail -1)
AIRPORT_BODY=$(echo "$AIRPORT_RESP" | sed '$d')

if [ "$AIRPORT_HTTP_CODE" != "200" ]; then
    echo "[ERROR] 机场API返回 $AIRPORT_HTTP_CODE"
    echo "$AIRPORT_BODY"
    exit 1
fi
echo "$AIRPORT_BODY" > "$DATA_DIR/airports.json"
echo "       ✓ 机场数据已保存 ($(echo "$AIRPORT_BODY" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'{d[\"total\"]}家')" 2>/dev/null || echo "OK"))"

# 拉取服务器数据
echo ">>> 拉取服务器数据..."
SERVER_RESP=$(curl -s -w "\n%{http_code}" "$API_BASE_URL/api/public/links/server")
SERVER_HTTP_CODE=$(echo "$SERVER_RESP" | tail -1)
SERVER_BODY=$(echo "$SERVER_RESP" | sed '$d')

if [ "$SERVER_HTTP_CODE" != "200" ]; then
    echo "[ERROR] 服务器API返回 $SERVER_HTTP_CODE"
    echo "$SERVER_BODY"
    exit 1
fi
echo "$SERVER_BODY" > "$DATA_DIR/servers.json"
echo "       ✓ 服务器数据已保存 ($(echo "$SERVER_BODY" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'{d[\"total\"]}家')" 2>/dev/null || echo "OK"))"

# 计算统计信息
echo ">>> 生成统计信息..."
python3 -c "
import json
with open('$DATA_DIR/airports.json') as f:
    airports = json.load(f)
with open('$DATA_DIR/servers.json') as f:
    servers = json.load(f)

stats = {
    'updated_at': '$TIMESTAMP',
    'airport_count': airports['total'],
    'server_count': servers['total'],
    'featured_count': sum(1 for a in airports['data'] if a.get('is_featured')),
    'min_price': min(
        float(p['price']) 
        for a in airports['data'] 
        for p in a['plans'] 
        if p['price']
    )
}
with open('$DATA_DIR/stats.json', 'w') as f:
    json.dump(stats, f, ensure_ascii=False)
print(f'       机场: {stats[\"airport_count\"]}家, 主推: {stats[\"featured_count\"]}家, 最低价: ¥{stats[\"min_price\"]}')
print(f'       VPS: {stats[\"server_count\"]}家')
"

# Git 提交
cd "$REPO_DIR"
git add _data/
git commit -m "📊 数据自动同步 @ $TIMESTAMP" || echo "       ℹ️  无变更，跳过提交"
git push origin main

echo ""
echo "=== 同步完成 ✅ ==="
