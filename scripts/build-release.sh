#!/bin/bash
# PromptCraft 发布构建脚本
# 用法: ./scripts/build-release.sh [版本号]
# 示例: ./scripts/build-release.sh 1.0.0

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 版本号（默认从 project.yml 读取或使用参数）
VERSION=${1:-"1.0.0"}
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="PromptCraft"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  PromptCraft 发布构建脚本 v$VERSION${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 清理旧构建
echo -e "${YELLOW}[1/5] 清理旧构建...${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Archive
echo -e "${YELLOW}[2/5] 构建 Archive...${NC}"
xcodebuild -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -archivePath "$BUILD_DIR/$APP_NAME.xcarchive" \
  archive \
  -quiet

if [ ! -d "$BUILD_DIR/$APP_NAME.xcarchive" ]; then
  echo -e "${RED}Archive 失败！${NC}"
  exit 1
fi
echo -e "${GREEN}Archive 完成${NC}"

# 导出 App
echo -e "${YELLOW}[3/5] 导出 App...${NC}"

# 创建导出选项
cat > "$BUILD_DIR/ExportOptions.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>destination</key>
    <string>export</string>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
  -archivePath "$BUILD_DIR/$APP_NAME.xcarchive" \
  -exportPath "$BUILD_DIR/export" \
  -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist" \
  -quiet

if [ ! -d "$BUILD_DIR/export/$APP_NAME.app" ]; then
  echo -e "${RED}导出失败！${NC}"
  exit 1
fi
echo -e "${GREEN}导出完成${NC}"

# 创建 DMG
echo -e "${YELLOW}[4/5] 创建 DMG...${NC}"

DMG_DIR="$BUILD_DIR/dmg"
DMG_NAME="$APP_NAME-$VERSION.dmg"

mkdir -p "$DMG_DIR"
cp -R "$BUILD_DIR/export/$APP_NAME.app" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

# 创建 DMG
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_DIR" \
  -ov \
  -format UDZO \
  "$BUILD_DIR/$DMG_NAME"

if [ ! -f "$BUILD_DIR/$DMG_NAME" ]; then
  echo -e "${RED}DMG 创建失败！${NC}"
  exit 1
fi
echo -e "${GREEN}DMG 创建完成${NC}"

# 生成校验和
echo -e "${YELLOW}[5/5] 生成校验和...${NC}"
cd "$BUILD_DIR"
shasum -a 256 "$DMG_NAME" > "$DMG_NAME.sha256"
echo -e "${GREEN}校验和已生成${NC}"

# 完成
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  构建完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "输出文件："
echo "  - $BUILD_DIR/$DMG_NAME"
echo "  - $BUILD_DIR/$DMG_NAME.sha256"
echo ""
echo "文件大小："
ls -lh "$BUILD_DIR/$DMG_NAME" | awk '{print "  " $5}'
echo ""
echo "SHA-256："
cat "$BUILD_DIR/$DMG_NAME.sha256"
echo ""
echo -e "${YELLOW}下一步：${NC}"
echo "  1. 测试安装: open $BUILD_DIR/$DMG_NAME"
echo "  2. 创建 Release: gh release create v$VERSION --title \"$APP_NAME v$VERSION\" $BUILD_DIR/$DMG_NAME"
echo ""
