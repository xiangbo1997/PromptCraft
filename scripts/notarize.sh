#!/bin/bash
# PromptCraft 公证脚本（需要 Apple Developer 账号）
# 用法: ./scripts/notarize.sh
#
# 前提条件:
# 1. 已加入 Apple Developer Program ($99/年)
# 2. 已创建 App 专用密码: https://appleid.apple.com/account/manage
# 3. 设置环境变量:
#    export APPLE_ID="your-email@example.com"
#    export APPLE_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"
#    export TEAM_ID="YOUR_TEAM_ID"

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="PromptCraft"
APP_PATH="$BUILD_DIR/export/$APP_NAME.app"

# 检查环境变量
if [ -z "$APPLE_ID" ] || [ -z "$APPLE_APP_PASSWORD" ] || [ -z "$TEAM_ID" ]; then
  echo -e "${RED}错误: 请设置以下环境变量:${NC}"
  echo "  export APPLE_ID=\"your-email@example.com\""
  echo "  export APPLE_APP_PASSWORD=\"xxxx-xxxx-xxxx-xxxx\""
  echo "  export TEAM_ID=\"YOUR_TEAM_ID\""
  echo ""
  echo "获取 App 专用密码: https://appleid.apple.com/account/manage"
  echo "获取 Team ID: https://developer.apple.com/account -> Membership"
  exit 1
fi

# 检查 App 是否存在
if [ ! -d "$APP_PATH" ]; then
  echo -e "${RED}错误: 找不到 App，请先运行 build-release.sh${NC}"
  exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  PromptCraft 公证脚本${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 创建 ZIP
echo -e "${YELLOW}[1/4] 创建 ZIP 文件...${NC}"
ZIP_PATH="$BUILD_DIR/$APP_NAME-notarize.zip"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
echo -e "${GREEN}ZIP 创建完成${NC}"

# 提交公证
echo -e "${YELLOW}[2/4] 提交公证请求...${NC}"
echo "这可能需要几分钟，请耐心等待..."

NOTARIZE_OUTPUT=$(xcrun notarytool submit "$ZIP_PATH" \
  --apple-id "$APPLE_ID" \
  --password "$APPLE_APP_PASSWORD" \
  --team-id "$TEAM_ID" \
  --wait 2>&1)

echo "$NOTARIZE_OUTPUT"

# 检查公证结果
if echo "$NOTARIZE_OUTPUT" | grep -q "status: Accepted"; then
  echo -e "${GREEN}公证成功！${NC}"
else
  echo -e "${RED}公证失败，请检查输出信息${NC}"
  exit 1
fi

# 装订票据
echo -e "${YELLOW}[3/4] 装订公证票据...${NC}"
xcrun stapler staple "$APP_PATH"
echo -e "${GREEN}票据装订完成${NC}"

# 验证
echo -e "${YELLOW}[4/4] 验证签名...${NC}"
spctl --assess --verbose=4 "$APP_PATH"
echo -e "${GREEN}验证通过${NC}"

# 重新创建 DMG
echo ""
echo -e "${YELLOW}重新创建已公证的 DMG...${NC}"
VERSION=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0.0")

DMG_DIR="$BUILD_DIR/dmg-notarized"
DMG_NAME="$APP_NAME-$VERSION-notarized.dmg"

rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"
cp -R "$APP_PATH" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_DIR" \
  -ov \
  -format UDZO \
  "$BUILD_DIR/$DMG_NAME"

# 生成校验和
cd "$BUILD_DIR"
shasum -a 256 "$DMG_NAME" > "$DMG_NAME.sha256"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  公证完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "已公证的 DMG 文件："
echo "  - $BUILD_DIR/$DMG_NAME"
echo ""
echo "用户下载后可以直接运行，无需在系统设置中手动允许。"
echo ""
