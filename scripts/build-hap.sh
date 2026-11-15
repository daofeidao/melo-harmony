#!/usr/bin/env bash
# 本地构建 Melo 鸿蒙版 HAP（未签名）
#
# 前置：
#   export DEVECO_SDK_HOME=/d/wb/tools/harmony/sdk/windows      # SDK 根目录（含 ets / toolchains）
#   npm i                                                        # 装 hvigor
#
# 用法：bash scripts/build-hap.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ -z "${DEVECO_SDK_HOME:-}" ]; then
  if [ -f local.properties ]; then
    echo "使用 local.properties 里的 sdk.dir"
  else
    echo "缺少 DEVECO_SDK_HOME，或先创建 local.properties（sdk.dir=...）" >&2
    exit 1
  fi
fi

if [ ! -d node_modules/@ohos/hvigor ]; then
  echo "安装 hvigor 依赖…"
  npm i --no-audit --no-fund --registry=https://repo.harmonyos.com/npm/
fi

node ./node_modules/@ohos/hvigor/bin/hvigor.js --mode module -p product=default assembleHap

echo
echo "产物："
find entry/build -name "*.hap" -maxdepth 6 2>/dev/null | while read -r f; do
  ls -lh "$f"
done
