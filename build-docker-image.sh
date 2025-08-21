#!/bin/bash

# NetLogo Web Docker 构建脚本
set -e

# 默认配置
IMAGE_NAME="netlogo-web"
TAG="latest"
PUSH_IMAGE=false
REGISTRY=""
NO_CACHE=false

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 显示帮助信息
show_help() {
    echo "NetLogo Web Docker 构建脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -t, --tag TAG        镜像标签 (默认: latest)"
    echo "  -n, --name NAME      镜像名称 (默认: netlogo-web)"
    echo "  -p, --push           构建后推送镜像"
    echo "  -r, --registry URL   镜像仓库地址"
    echo "  --no-cache           不使用构建缓存"
    echo "  -h, --help           显示帮助信息"
    echo ""
    echo "说明:"
    echo "  使用 'sbt run' 启动 NetLogo Web，支持热重载"
    echo ""
    echo "示例:"
    echo "  $0                                    # 构建镜像"
    echo "  $0 --tag v1.0                        # 构建带标签的镜像"
    echo "  $0 --push --registry hub.docker.com/myorg  # 构建并推送镜像"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
  case $1 in
    -t|--tag)
      TAG="$2"
      shift 2
      ;;
    -n|--name)
      IMAGE_NAME="$2"
      shift 2
      ;;
    -p|--push)
      PUSH_IMAGE=true
      shift
      ;;
    -r|--registry)
      REGISTRY="$2"
      shift 2
      ;;
    --no-cache)
      NO_CACHE=true
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      print_error "未知选项: $1"
      show_help
      exit 1
      ;;
  esac
done

# 构建完整的镜像名称
FULL_IMAGE_NAME="${IMAGE_NAME}:${TAG}"
if [[ -n "$REGISTRY" ]]; then
  FULL_IMAGE_NAME="${REGISTRY}/${FULL_IMAGE_NAME}"
fi

# 显示构建信息
echo "🚀 开始构建 NetLogo Web Docker 镜像..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_info "镜像名称: $FULL_IMAGE_NAME"
print_info "使用缓存: $([ "$NO_CACHE" = true ] && echo "否" || echo "是")"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 检查 Docker 是否可用
if ! command -v docker &> /dev/null; then
    print_error "Docker 未安装或不可用"
    exit 1
fi

# 构建 Docker 镜像
print_info "开始构建镜像..."

BUILD_ARGS=""
if [[ "$NO_CACHE" == true ]]; then
    BUILD_ARGS="--no-cache"
fi

if docker build $BUILD_ARGS -t "$FULL_IMAGE_NAME" .; then
    print_success "镜像构建完成: $FULL_IMAGE_NAME"
else
    print_error "镜像构建失败"
    exit 1
fi

# 显示镜像信息
print_info "镜像信息:"
docker images "$FULL_IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

# 推送镜像（如果需要）
if [[ "$PUSH_IMAGE" == true ]]; then
    if [[ -z "$REGISTRY" ]]; then
        print_warning "未指定镜像仓库地址，跳过推送"
    else
        print_info "推送镜像到仓库..."
        if docker push "$FULL_IMAGE_NAME"; then
            print_success "镜像推送完成"
        else
            print_error "镜像推送失败"
            exit 1
        fi
    fi
fi

echo ""
print_success "🎉 构建流程完成！"
echo ""
print_info "💡 使用方法:"
echo "   启动服务: docker-compose up"
echo "   或直接运行: docker run -p 9000:9000 -v \$(pwd):/app $FULL_IMAGE_NAME"
echo ""
print_info "🌐 访问地址: http://localhost:9000"
