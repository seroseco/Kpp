#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_INSTALL_DIR="$HOME/.local/bin"
INSTALL_DIR="$DEFAULT_INSTALL_DIR"
FORCE=false

usage() {
  cat <<'USAGE'
Usage:
  ./install.sh [--dir <install_dir>] [--force]

Options:
  --dir <path>   Install directory (default: ~/.local/bin)
  --force        Overwrite existing file/symlink without prompt
  -h, --help     Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)
      if [[ $# -lt 2 ]]; then
        echo "[K++] 오류: --dir 값이 필요합니다." >&2
        exit 1
      fi
      INSTALL_DIR="$2"
      shift 2
      ;;
    --force)
      FORCE=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[K++] 오류: 알 수 없는 옵션 '$1'" >&2
      usage
      exit 1
      ;;
  esac
done

mkdir -p "$INSTALL_DIR"
TARGET="$INSTALL_DIR/kpp"
SOURCE="$ROOT_DIR/kpp"

if [[ ! -f "$SOURCE" ]]; then
  echo "[K++] 오류: kpp 실행 파일을 찾을 수 없습니다: $SOURCE" >&2
  exit 1
fi

if [[ -e "$TARGET" && "$FORCE" != true ]]; then
  echo "[K++] 이미 존재합니다: $TARGET" >&2
  echo "[K++] 덮어쓰려면 --force 옵션을 사용하세요." >&2
  exit 1
fi

ln -sfn "$SOURCE" "$TARGET"
chmod +x "$SOURCE"

echo "[K++] 설치 완료: $TARGET"

auto_path_notice=true
case ":$PATH:" in
  *":$INSTALL_DIR:"*) auto_path_notice=false ;;
esac

if [[ "$auto_path_notice" == true ]]; then
  echo "[K++] PATH에 '$INSTALL_DIR'가 없습니다. 아래를 셸 설정 파일(~/.zshrc 등)에 추가하세요:"
  echo "export PATH=\"$INSTALL_DIR:\$PATH\""
fi

echo "[K++] 확인: kpp --help"
