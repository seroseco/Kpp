#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

INIT_FILE="$TMP_DIR/practice.kpp"
COLLISION_FILE="$TMP_DIR/collision.kpp"
NO_COLLISION_FILE="$TMP_DIR/no_collision.kpp"

assert_contains() {
  local text="$1"
  local expected="$2"
  if [[ "$text" != *"$expected"* ]]; then
    echo "[FAIL] expected output to contain: $expected" >&2
    echo "[INFO] actual output:" >&2
    echo "$text" >&2
    exit 1
  fi
}

echo "[TEST] kpp init"
out="$(./kpp init "$INIT_FILE")"
assert_contains "$out" "생성 완료"
[[ -f "$INIT_FILE" ]]

echo "[TEST] kpp init --help"
out="$(./kpp init --help)"
assert_contains "$out" "Usage:"

echo "[TEST] init file run"
out="$(./kpp --safe --run "$INIT_FILE")"
assert_contains "$out" "K++ 시작!"

echo "[TEST] --safe collision detect"
cat > "$COLLISION_FILE" <<'SRC'
#포함 <iostream>
사용 범위 표준;
정수 진입() {
  정수 정렬 = 1;
  출력 << 정렬 << 끝줄;
  반환 0;
}
SRC

set +e
out="$(./kpp --safe "$COLLISION_FILE" 2>&1)"
status=$?
set -e

if [[ $status -eq 0 ]]; then
  echo "[FAIL] --safe expected non-zero exit code on collision" >&2
  exit 1
fi
assert_contains "$out" "키워드 충돌 감지"

echo "[TEST] --safe ignores strings and comments"
cat > "$NO_COLLISION_FILE" <<'SRC'
#포함 <iostream>
사용 범위 표준;
정수 진입() {
  // 정수 정렬 = 1;
  문자열 msg = "정수 정렬 = 1";
  출력 << msg << 끝줄;
  반환 0;
}
SRC
./kpp --safe "$NO_COLLISION_FILE" >/dev/null

echo "[PASS] cli feature tests passed"
